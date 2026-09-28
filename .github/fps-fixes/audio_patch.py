"""Exact DEV15.16 audio-position cadence patch; no PCM/playback graph changes.

API: transform_js(original: str)->str; transform_worklet(original: str)->str.
CLI: audio_patch.py ORIGINAL_DIR OUTPUT_DIR (writes only the two audio JS files).
"""
import hashlib
from pathlib import Path

EXPECTED_JS_SHA256 = "4cb9a7427e6528dd04c42bfad1433fd88ddd4f27e49450cced41694ee54cda7f"
EXPECTED_WORKLET_SHA256 = "be33985bc7160d6bf9646f259cd86b259cd67b02ccb297ee5c44f8ac84327bc8"


def _once(text: str, old: str, new: str) -> str:
    assert text.count(old) == 1, f"Unexpected source token: {old[:100]}"
    return text.replace(old, new, 1)


def transform_js(original: str) -> str:
    assert hashlib.sha256(original.encode()).hexdigest() == EXPECTED_JS_SHA256
    text = _once(
        original,
        'this._positionWorklet.port.onmessage=event=>{switch(event.data["type"]){',
        'this._positionWorklet.port.onmessage=event=>{if(!globalThis.FPS_FIX_AUDIO.observe(this._positionWorklet,event.data)){return}switch(event.data["type"]){',
    )
    text = _once(
        text,
        '};const resetParameter=this._positionWorklet.parameters.get("reset");',
        '};globalThis.FPS_FIX_AUDIO.attach(this._positionWorklet,Boolean(this.getSample()._audioBuffer&&this.getSample()._audioBuffer.duration>10));const resetParameter=this._positionWorklet.parameters.get("reset");',
    )
    text = _once(
        text,
        'if(this._positionWorklet){this._positionWorklet.disconnect();this._positionWorklet.port.onmessage=null;',
        'if(this._positionWorklet){globalThis.FPS_FIX_AUDIO.detach(this._positionWorklet);this._positionWorklet.disconnect();this._positionWorklet.port.onmessage=null;',
    )
    # Keep the existing PCM reuse guard and all original sample lifecycle code.
    assert text.count('this._audioBuffer.duration>10') == original.count('this._audioBuffer.duration>10') == 1
    return Path(__file__).with_name('audio-runtime.js').read_text() + '\n' + text


def transform_worklet(original: str) -> str:
    assert hashlib.sha256(original.encode()).hexdigest() == EXPECTED_WORKLET_SHA256
    text = _once(original, '\t\tthis.position = 0;\n\t}', '''\t\tthis.position = 0;
\t\tthis._reportFrames = 0;
\t\tthis._pendingFrames = 0;
\t\tthis._hadInput = false;
\t\tthis._previousReset = false;
\t\tthis._lastInputPosition = 0;
\t\tthis._fpsFixVersion = 0;
\t\tthis.port.onmessage = event => {
\t\t\tconst message = event.data;
\t\t\t// Original `clear` is deliberately still ignored. Do not change restart semantics.
\t\t\tif (!message || message.type !== 'fps-fix-reporting') return;
\t\t\tconst hz = message.hz === 60 ? 60 : 0;
\t\t\tthis._fpsFixVersion = message.version;
\t\t\tthis._reportFrames = hz ? sampleRate / hz : 0;
\t\t\tthis._pendingFrames = 0;
\t\t\t// A new owner or cadence takes effect at the next exact input quantum.
\t\t\tthis._hadInput = false;
\t\t\tthis.port.postMessage({ type: 'fps-fix-configured', hz, version: message.version });
\t\t};
\t}''')
    start = text.index('\tprocess(inputs, _outputs, parameters) {')
    stop = text.index('\n\t}\n}', start) + len('\n\t}')
    process = '''\tprocess(inputs, _outputs, parameters) {
\t\tconst reset = parameters['reset'][0] > 0;
\t\tif (reset) this.position = 0;
\t\tconst input = inputs.length > 0 ? inputs[0] : [];
\t\tif (input.length > 0) {
\t\t\tconst frames = input[0].length;
\t\t\tthis.position += frames;
\t\t\tthis._lastInputPosition = this.position;
\t\t\tthis._pendingFrames += frames;
\t\t\tconst force = !this._hadInput || reset !== this._previousReset;
\t\t\tif (!this._reportFrames || force || this._pendingFrames >= this._reportFrames) {
\t\t\t\tthis.port.postMessage({ type: 'position', data: this.position, fpsFixVersion: this._fpsFixVersion });
\t\t\t\tthis._pendingFrames = this._reportFrames && !force ? this._pendingFrames % this._reportFrames : 0;
\t\t\t}
\t\t\tthis._hadInput = true;
\t\t} else {
\t\t\t// Final partial cadence on pause/stop: publish the last actual input count,
\t\t\t// even if the original reset parameter zeroed the internal counter above.
\t\t\tif (this._hadInput && this._pendingFrames > 0) {
\t\t\t\tthis.port.postMessage({ type: 'position', data: this._lastInputPosition, fpsFixVersion: this._fpsFixVersion });
\t\t\t}
\t\t\tthis._pendingFrames = 0;
\t\t\tthis._hadInput = false;
\t\t}
\t\tthis._previousReset = reset;
\t\treturn true;
\t}'''
    return text[:start] + process + text[stop:]


if __name__ == '__main__':
    import sys
    assert len(sys.argv) == 3, 'Usage: audio_patch.py ORIGINAL_DIR OUTPUT_DIR'
    source, output = map(Path, sys.argv[1:])
    output.mkdir(parents=True, exist_ok=True)
    (output / 'index.js').write_text(transform_js((source / 'index.js').read_text()))
    (output / 'index.audio.position.worklet.js').write_text(transform_worklet((source / 'index.audio.position.worklet.js').read_text()))

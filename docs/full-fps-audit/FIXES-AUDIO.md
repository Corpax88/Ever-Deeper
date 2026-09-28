# Audio position-message candidate — 2026-09-28

## Concrete change

The exact DEV15.16 position AudioWorklet posts a message after every input
quantum. At48kHz and128 frames that is375 messages/second per playing sample.
The three long music samples are eligible for a60Hz reporting cadence. Short
SFX keep the original every-quantum cadence. The processor still counts every
input sample and publishes exact accumulated counts; it does not skip audio
samples or change the audible source graph, gain, PCM, playback rate, or stream
start/stop scheduling.

Only `index.js` and `index.audio.position.worklet.js` change. The patch module is
`.github/fps-fixes/audio_patch.py`, exposing:

```python
transform_js(original: str) -> str
transform_worklet(original: str) -> str
```

Both refuse unexpected input SHA256 identities:

- `index.js`: `4cb9a7427e6528dd04c42bfad1433fd88ddd4f27e49450cced41694ee54cda7f`
- position worklet: `be33985bc7160d6bf9646f259cd86b259cd67b02ccb297ee5c44f8ac84327bc8`

`transform_js` prepends sibling `audio-runtime.js` automatically. No HTML
installer is required. The existing `this._audioBuffer.duration>10` PCM reuse
guard remains verbatim. Eligibility uses that same duration boundary; future
long SFX would require revisiting the current music-only asset assumption.

## Timing difference, deliberately bounded

There is **no claim of identical position freshness**. The last reported getter
value may lag the original by at most a60Hz reporting interval plus one render
quantum before message-delivery delays. In the deterministic128-frame tests the
maximum additional stale sample gap is14.51ms at44.1kHz and16ms at48/96kHz.
The existing music director uses this getter for its four-second crossfade
threshold, so the threshold may be reached that much later. Actual main-thread
message scheduling is a browser concern and remains subject to the browser test.

First input, reset transitions, and input stopping publish immediately. A final
partial cadence on pause/stop flushes the last actual input sample count. There
is no wall-clock extrapolation and therefore no accumulated position drift or
advance during a suspended AudioContext. Version-tagged reports reject queued
messages from a prior owner when a pooled worklet is reused.

CurrentTime-based extrapolation was considered and rejected as a higher-risk
change: this exact engine resets its accumulator every quantum during the
existing one-second reset pulse, ignores its `clear` restart message, and reports
output input-frame counts. Extrapolating source position would also interact with
playback-rate/loop handling. This patch preserves those existing behaviors,
including the one-second reset schedule and ignored `clear`; it does not quietly
repair unrelated engine behavior.

## Runtime API and measurement

```js
window.FPS_FIX_AUDIO.setEnabled(false); // original reporting cadence on existing nodes
window.FPS_FIX_AUDIO.setEnabled(true);  // 60Hz music; unchanged cadence for SFX
window.FPS_FIX_AUDIO.snapshot();
```

Default is enabled. A browser init script can set
`window.FPS_FIX_AUDIO_START_ENABLED = false` before `index.js` executes.
`snapshot()` reports active nodes, eligibility, requested/confirmed cadence and
configuration version, total received position messages, configuration sends/
receipts, and rejected stale position messages. Use before/after differences;
wait for every active node's `version === confirmedVersion` before measuring a
mode. These are inexpensive counters, not a message-timestamp profiler.

The in-page off/on comparison includes the patch's extra hooks in both modes.
The final performance comparison must therefore also retain an untouched
original-export page versus the patched production files, to account for all
new bookkeeping overhead. Repeated volume writes remain unchanged so this is
one distinct audio hypothesis.

## Meaningful deterministic tests

```sh
node .github/fps-fixes/audio-test.mjs ORIGINAL_DIR [CANDIDATE_DIR]
```

With one argument, the test builds a temporary candidate using the patch module.
With two arguments, it tests the actual packaged candidate. Tests execute the
original and patched worklet source plus the actual exported `Sample` and
`SampleNode` classes with controlled AudioContext/source/port scheduling.

Local result:15 groups pass, plus syntax checks on the helper and both patched
JS files. Coverage includes:

- exact every-quantum SFX/unconfigured reporting and unchanged output samples;
- all sample counts at44.1/48/96kHz with64/128/256-frame render quanta;
- pause/no-input final flush and no position advancement during suspension;
- minute-long crossfade threshold/no-drift comparisons;
- the actual exported pause/resume, loop restart, ended/stop/start, crossfade
  overlap, SFX overlap, worklet-pool reuse, and cancel-before-ready lifecycle;
- music PCM object identity, unchanged short-SFX duplication, rejected stale
  previous-owner reports, received configuration acknowledgements, and no
  retained active stream records after stopping.

| Deterministic scenario | Original messages | Candidate messages | Additional threshold delay |
|---|---:|---:|---:|
| 62s at44.1kHz /128 frames | 21361 | 3720 | 5.80ms |
| 62s at48kHz /128 frames | 23250 | 3720 | 5.33ms |

The actual exported lifecycle produced the same35 audible source/graph/offset
operations in both versions. All10 configuration messages were acknowledged;
the deliberately injected stale report was rejected; active records ended at0.
These tests establish deterministic state/sample behavior, not audible device
quality or browser performance. Mac original/candidate measurements and any
production decision belong to the parent workflow. No publication or prepass
change is included here.

## Separate volume-write observation

The exact export's `GodotAudio.SampleNodeBus.setVolume(volume)` unconditionally
writes six channel gain values whenever invoked. It is not proven that the
engine invokes it for unchanged per-frame `AudioStreamPlayer.volume_db` writes.
Suppressing equal writes could be studied separately after observing those
calls, but it is deliberately absent from this cadence patch.

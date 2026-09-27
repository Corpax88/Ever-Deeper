# DEV15.11: remove music-start copies and retain stable reusable PCM

The music start path copied whole decoded tracks and retained extra registered buffers. DEV15.11 prepares three private nonlooping MP3 streams once and returns their existing long PCM buffers when playback starts. New playback nodes, offsets, gain and crossfades remain independent. Clean production source: ba396beeed9e587a8dc700edef7b28b79f1095d6; immutable candidate from run36303234754. No art, lights, resolution, hero, pet, gameplay or save-path change.

Targeted audio.play measurements fell from166–299ms to0–1ms. All three tracks, simultaneous playback with independent offsets, mute, pause/resume and volume were verified in WebKit/Apple GPU and Chromium/Metal. Six final exported core cases and ordinary clean-package startup/save/reload passed. Prior independent visual acceptance of the clean package is retained.

## Final controlled performance gate

Run36317867786, source1d46c8ea9d48a10f44dd3a71aedcea661cb1a0c1. Two Mac WebKit/Apple GPU workers,2328×1260/DPR3,64 balanced adjacent AB/BA pairs each,4s active-mining windows after1.5s settling. Original and candidate use separate browser processes and separate audio registries. Inactive engine loops and audio contexts are paused; browser GPU processes remain running. QA-only common Emscripten keepalive wrappers prevent paused runtimes from exiting. All256 windows passed actual rendered-pixel, zero-context-loss, active-mining, advancing-audio and unchanged-inactive-frame gates; all3098 checks passed. First/last actual images from both workers were inspected, including full-size final pairs; same scene, lighting, assets and actors with expected animation-phase differences.

Predeclared analysis uses16 eight-pair block means, retains every pair/outlier, requires each worker mean above-2% and pooled lower95% t confidence bound above-2%. Worker means+2.453528% and-1.211133%; pooled+0.621198%,95%CI[-1.097944%,+2.340340%]. Gate PASSED. This establishes only the bounded noninferiority criterion in this controlled setup, not a sustained-FPS increase or physical-iPhone performance.

Weighted FPS:50.7618→51.7179 and47.7334→46.9903. Worst observed frames348→80ms and327→124ms. Slow-frame counts396→353 and502→554; the second worker's slow-frame count did not improve. Original tracked long PCM grew2/63,269,744bytes→8/248,149,952bytes; candidate remained3/92,440,104bytes. Candidate startup memory is higher; do not claim lower initial or total browser memory. Both games were resident simultaneously in this diagnostic.

Artifacts10931358853/music-controlled-1,17,820,635bytes,SHA256927ec7cd74e9ca32df5a9a140091cce0a5444609253ba8d899dc02f2eb8bf94b;10931796298/music-controlled-2,17,798,105bytes,SHA25692ce5cd098d5f2334736dcbeb3ec7df174ba89e48ffd879674ce25fc42515473. Downloaded size,SHA andZIP CRC verified. Compact committed evidence retains every measured window, check and statistic; raw traces and console transcripts remain in these pinned artifacts.

## Earlier results remain part of the record

Same-context paired run36303672796 was inconclusive and suffered original-buffer carryover, subsequently confirmed through strong registry ownership in run36314151070. Fresh-process run36315042649 was inconclusive:+4.742481%,95%CI[-3.872411%,13.357374%]. No thresholds or outliers were changed to accept either.

OS-suspension run36316407143 is INVALID: original screenshots became black while frame counters continued. Its apparent regression is not a game result. Corrected pause run36317657662 collected no measured windows because the QA pause released Emscripten's sole keepalive and ended the engine; the balanced QA lifetime wrapper fixed this. Focus run36316992998 confirmed both pages visible/focused but did not resolve the original rendering failure by itself.

## Publication boundary

Publish only the nine reviewed DEV15.11 files from the immutable candidate artifact. Preserve all nine LIVE files, all nine Worn-trial files and existing DEV saves. The publisher validates provenance, evidence hashes and the performance criteria again, keeps DEV15.10 rollback bytes, then verifies all27 public hashes. Main is a publication carrier only; never export this game from main. Physical iPhone FPS is still unverified; the prior39.23FPS phone report is not claimed solved by this release.

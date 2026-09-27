# Isolated playback comparison — criteria declared before execution
Eight adjacent balanced AB/BA pairs on each of two Mac workers; fixed sequence, no optional stopping or discarded outliers.
Each observation uses a fresh browser process. Require all Playwright WebKit children exited before the next launch.
Exact canonical original audio source ab0c12f versus candidate ba396be, with the same QA scene/fixture and JS candidate PCM patch. Original does NOT preload candidate buffers.
Target: 776x420 CSS, DPR3, Apple GPU, fixed durable active mining; 15s warmup, 30s observation; function profiling off.
Primary: percent FPS change per adjacent pair, candidate/original-1. Require pooled lower 95% two-sided paired t interval above -2%, and each worker's mean above -2%. Preserve earlier margin. Insufficient evidence remains insufficient; do not loosen it after looking.
Startup duration and live PCM are separate secondary telemetry; do not claim RSS or physical-iPhone results.
Capture first/last pair states per worker; existing unchanged lifecycle/core results remain valid.
This test addresses prior strong-registry carryover. It does not alone prove phone FPS or universal stutter freedom.

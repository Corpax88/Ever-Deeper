# Wider terrain groups — not promoted; retain production width6

Completed e212cf5cbc5bb7247f5aa8aba5d3f6c8ccc9a4f7/run36117760988. Both266checks,66 exact pixel pairs and9mining windows; all18windows retained. All16PNG independently inspected via4 SHA-identical content groups. Four mines, damage/break/restore, five lightstyles and moved camera remain exact. Two balanced mining orders on Mac Apple/WebKit, full2328x1260.

Width6/12/24 weightedFPS50.2297/50.2205/51.8701 and47.9218/47.2104/48.9160. Width12 flat/worse. Width24 +3.27%/+2.07%, setup/frame1.785→1.398ms and1.878→1.519ms, but mixed p95 and worker2worst411ms versusoriginal84ms. Worker1original361ms also retained. CPU target confirmed but no strong total benefit. Independent review agrees: retain width6 forDEV15.10, width24 only as unaccepted exploration; no phone claim. Do not repeat unchanged trial.

Artifacts10856465773(36667560bytes) and10855763511(36694855bytes), exactsize and ZIP verified. Ordinary default stayed6 throughout; no public source behavior change. Final release is the separately accepted CPU/native/shared-HUD candidate.

## Original experiment plan (historical)

# Wider terrain groups — isolated experiment, not accepted

Sourcee212cf5cbc5bb7247f5aa8aba5d3f6c8ccc9a4f7 on codex/wide-strip-study-20260925, based on shared-HUD4f27644. Earlier narrower3/1 groups were rejected for worse mining; widths12/24 have not been tested. Current setup CPU remains around1.2–1.3 seconds per15-second mining window. Larger groups may reduce that cost but increase light-bound work/redraw area, so no performance inference from group/draw-call counts alone.

Default width stays6. Explicit QA changes6/12/24, invalidates caches on every change, retains ordered four authored passes and row/cell order. Exact frozen parity across four mines, intact/damage/break/restore, five lighting styles and moved camera is required. Two Mac Apple/WebKit workers,2328x1260, prewarm all modes, wait60s, then9 balanced12s held-mining windows each; real mouse held, active hero/fixed position/impacts checked. No duplicate idle matrix and no unavailable GPU timer instrumentation. Preserve all windows and drift. Only a measured, visually exact winner could become a production candidate.

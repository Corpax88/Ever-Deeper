# Canonical run saves, schema 3

The current runtime uses one typed binary `.sav` format with a 44-byte header,
SHA-256 integrity, object-disabled decoding and a retained atomic backup.
The dictionary import/export API remains canonical schema 3. Old documents
and old JSON files are intentionally invalidated; there is no parallel loader.

Work was paused on 2026-09-16 at the user's **SAVE FOR NEW CHAT** request.
[The detailed handoff](HANDOFF-20260916.md) is authoritative for scope,
remaining checks, exact files and source hashes. This is not a completed
premium-polish or current full-suite acceptance claim.

The latest focused persistence gate passed **341 checks**. Its result is in
`save-results.json` and `save-log.txt`. The final 1,000-band save-cost probe
measured **12.03–12.28 ms while Blender and other work were running**;
`binary-save-cost-contended.json` records that result. An earlier integrated
binary revision measured 9.25–11.02 ms. The requested clean, exclusive probe
was canceled at the pause and still needs to run.

`json-save-cost.json`, `json-save-results.json`, `save-cost.json`,
`reviewed-files.json` and `gameplay-results.json` are evidence from the preceding
JSON implementation and are retained only as labeled history/baselines. They
do not certify current binary runtime or the current shared world source.
`binary-save-pilot*.json` are isolated pre-integration prototypes.
`frozen-source-sha256.json` identifies the paused source; it is not a test result.

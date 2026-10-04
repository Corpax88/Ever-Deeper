# Lifetime achievement save recovery

Achievement records previously overwrote their only JSON file directly and silently dropped write failures. A truncated file could erase achievements earned in earlier runs, even when the separate expedition save recovered correctly.

The existing JSON `{ "records": { "achievement_id": timestamp } }` format and DEV/LIVE filenames are retained. The writer now flushes and verifies a temporary generation before rotating a valid primary to `.bak`; a corrupt primary cannot replace the good backup. Failed commits keep records in memory and retry at a bounded six-second cadence with stale timer cancellation. On load, invalid/truncated primary JSON falls back to the previous valid generation and schedules a repair. Existing record IDs and timestamps are retained. Temporary uncommitted documents are not loaded.

`tools/review_achievement_recovery.gd` injects real temporary-path failures, verifies unchanged old generations, waits for automatic retry without another achievement, truncates a committed primary and tests backup recovery/repair. It also checks invalid timestamps and ignored temporary files. Use disposable `XDG_DATA_HOME`; runtime verification is pending. This does not recover a lost/evicted browser origin or both generations being damaged.

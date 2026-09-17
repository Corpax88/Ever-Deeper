# Recorded-data boundary result

The final headless replay passes 1036 checks using both actual 77-frame native
candidate reports. Every one of the 154 original PNG hashes and draw IDs was
verified before its recorded acknowledgment. The physical position/mining/HP
records and input events remain exact; request coalescing retains source IDs and
ordered physical records. Invalid fractional IDs, unpresented/changed source
phases, mutated source IDs and out-of-order event batches are rejected.

The original schema-2 manifest has 96 declared poses across right/up, including
30 bridge samples. Across all 12 state/heading goals per pose, the audit gives
1152 rows: 6 declared edges (timing not validated), 66 same-state/heading buckets,
720 missing edges and 360 bridge-policy gaps. Left/down views are absent. The
ordinary-input graph is not closed and must not replace production.

The replay observed 15 actual bridge frames for right and 13 for up; these are
rendered time samples, not proof that every authored endpoint was displayed.
A prototype replay also passed before strict fractional-index rejection was
added; its repeated summary rows were corrected. Retained prototype output is
not the source-bound final gate.

No renderer, gameplay source, pilot asset or current consumer was changed. This
result establishes an offline boundary only; live renderer acknowledgment,
impact presentation/deadlines, variable speed, lifecycle and recovery remain
unimplemented. These constraints apply to either a future finite raster graph
or a separately reviewed native rig architecture.

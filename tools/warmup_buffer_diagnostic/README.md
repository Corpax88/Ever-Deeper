# Original versus rejected warmup: existing WebGL buffer trace

The full warmup candidate5e48e4e failed seven touch suites in run35248670186.
Pause itself completes nine checks in both engines, but the original browser
error gate detects an element-buffer bind to a different target and subsequent
bufferSubData with no buffer. The previous published5ca6f0f package passed all14jobs.

This diagnostic uses exactly those two immutable nine-file exports. No export,
runtime source, art, input route or assertion is changed. The existing byte-bound
capture-web.mjs TRACE_GL_BUFFERS path records weak buffer identity/targets,16recent
binds and a stack for at most16conflicts. It forwards unchanged arguments and makes
no extra GL call or getError query. It is diagnostic and is not a timing mode.

One Linux CI job runs the original baseline then the rejected candidate, using a
fresh Chromium process/context per case and identical848×390CSS/DPR2 touch-pause
settings. The baseline must exit0 without conflicts or WebGL errors. The candidate
must retain its nonzero original exit, the same two raw WebGL errors, nine passing
pause checks, and an actual cross-category bind record with stack. Anything else
is inconclusive. A green diagnostic job only confirms reproduction; the candidate
remains rejected and no shader/cache/performance/publication acceptance follows.

Godot4.7.2 Polygon2D's unchanged-topology redraw uses an internal mesh update.
Primary source inspected by the independent critic has mesh_surface_update_index_region
binding an index buffer as GL_ARRAY_BUFFER. This predicts the observed error pair,
but the trace is needed to attribute the actual call path. Ordinary freed-ID reuse
is not established: Utilities deletes buffers and shipped engine JS creates fresh
objects. A direct non-indexed CanvasItem triangle command is a later possible
workaround, subject to this attribution and independent source/actual-render review.

Review and checkpoint these four preparation files first. A fresh REQUEST.json must
be its only direct-child change, pin this pins.json SHA, declare two sequential
sessions on attempt1, and name probe existing_buffer_trace_two_packages_v1.
No request is present in preparation. No automatic retry, published-game mutation
or specializations session occurs in this workflow.

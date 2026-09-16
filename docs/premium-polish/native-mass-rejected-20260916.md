# Native rock mesh experiment — rejected

Not in production. Cached native rock rows reduced draw calls, without a material
frame-time gain. This experiment and its runtime flag, shader and QA entry have
been removed. Native material detail remains unchanged.

At actual1696×780 under isolated Mesa llvmpipe, frozen A/B/A averages were
45.284 /47.084 /46.419FPS, GPU medians16.303 /16.394 /16.276ms.
Draw calls146→115. This does not meet the sustained50FPS requirement.

The initial sampler differed only at source-tile borders. Clamping the native
96px source regions brought ten fixed pairs to21–36 differing pixels per image,
maximum one byte. The correction was not independently timed. The small earlier
gain therefore cannot be claimed for the corrected implementation.

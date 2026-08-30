# Ever Deeper v0.42.0-dev.5

- Rebuilt excavated cave borders as continuous, irregular rock ribbons instead of repeating a full wall prop on every tile.
- Added connected corner joins, deterministic stone variation, and dedicated bedrock treatment without changing mining or collision.
- Applied the edge treatment to all four Depth 1 mines and their Depth 2 cave systems.
- Moved cave edges into a separate render pass so neighboring terrain can no longer clip the wall flow.

This is a DEV preview. Production remains unchanged.

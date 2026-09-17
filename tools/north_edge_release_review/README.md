# Moss north-edge production integration

The seven-state study at `74a0f772b0445dc3dfe82a3ecc4f014400318dd4`
was independently reviewed in 14 full-resolution A/B originals; all seven A2
images independently decoded exactly equal to A. Its narrow orientation fix
is now in `EndlessDescentWorld`, only for the exact mineable Moss texture and
north side. Native pixels, segment phase, horizontal reflection and world
quad are retained. Other biomes, bedrock, corners and gameplay remain as before.

This fixture reuses the held case from the original study (same seed, player,
camera, shader-time freeze and geometry checks). Unlike the study, B delegates
to the actual production owner. A and A2 replay the exact DEV11 edge owner.
The only changes to the original fixture are its resource paths, completion
prefix and scope text. The fixture defaults to A and ordinary scenes never
load its reference subclass. Compare its actual B pixels with the accepted
held-study B, and inspect the originals before accepting integration.

Run through `tools/run_rendered_isolated.py`, with the exact checkpoint SHA,
1696x780 and `NORTH_EDGE_RELEASE_REVIEW_COMPLETE`. A fresh isolated output is
required. Source and immutable-package runs can use the same fixture.

Prior seven-case report SHA256:
`c300dacfb47411c91a47a995a29dec16017129ee35e26ba163bf85bab14958a5`.
Independent root review SHA256:
`c096e15387577e63052fb85c5e911fbd86fd7922dbecdd088963a2261e910e07`.

Existing sideways rocks, full-size elbow/step joins and square biome boundaries
remain unresolved. This is no animation, FPS, iPhone or whole-game approval.

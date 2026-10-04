# Companion feedback and hero training

The Earthshaker sound call used the default `train_hero=true`, awarding a hero mining swing, precision hit and 4 Mining XP when only the mole excavated. Reproduced against exact first-candidate production PCK: four real cells excavated, but hero XP/counters incorrectly increased. Ordinary companion work already suppresses this training.

The mole's Earthshaker feedback now explicitly suppresses hero training. The same correction for Tunnel Home is included in the separately checkpointed map/main change. Mining sound, mole rewards, prospecting and authored animation are preserved.

`tools/review_companion_training.gd` uses the real Deep world and real mole action, then an actual hero strike. Against the isolated corrected overlay, all four assertions pass: four cells excavated, hero XP/counters unchanged by the mole, and the hero's own strike still earns exactly 4 XP and one swing. Godot 4.7.2 native headless; isolated disposable save roots; no runtime errors. This test establishes accounting, not audio listening quality. Overlay PCK SHA256 `6a94c645c4d391d5417aac22f98a9ef79c9dea180b1cacd0ee432bef91d8761b`; all other baseline payloads verified unchanged.

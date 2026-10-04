# Package footprint — independent read-only review

**Recommendation: retain the current package for this release. No substantial, safety-proven QA/report cleanup justifies changing the final candidate.** The package is large, but its size is predominantly art. This review neither changes approved resources nor resumes the parked FPS investigation.

Inspected the exact published DEV15.54 PCK, SHA-256 `7637ed10116bca208f841c11ea8d9359f4057b925fe2bc20bc1cda9ec267f56d`. All directory MD5s were verified and each payload was independently hashed. The package is **327,687,342 bytes with 1,591 entries**; earlier references to 1,588 described retained entries in a particular overlay, not the baseline's total. Directory/alignment overhead is only 174,546 bytes. The full per-file inventory is in `evidence/package-footprint/inventory.json`.

These are stored byte counts, not measured compressed network transfer, startup time, GPU memory or physical-phone performance.

## Where the bytes go

| Payload type | Bytes | Share of PCK |
| --- | ---: | ---: |
| Imported textures (`.ctex`) | 221,971,416 | 67.74% |
| PNG resources | 65,880,016 | 20.11% |
| Native raw texture files | 9,266,848 | 2.83% |
| Scenes and binary resources | 17,445,146 | 5.32% |
| Music streams | 4,854,141 | 1.48% |
| GDScript source and compiled scripts | 3,754,443 | 1.15% |

Associating imported textures with their actual logical owners gives 72.23 MB for `assets/hero`, 43.99 MB for surface art, 43.76 MB for UI, 32.15 MB for Treasury, 30.09 MB for `assets/characters`, 17.63 MB for companion art and 29.11 MB for native hero/tool resources. MB here means 1,000,000 bytes.

The largest individual payload is `assets/native-worn/orm.png.raw` at 4,566,913 bytes. Other large entries include the Treasury slate floor (3,009,693), worn runtime scene (2,896,810), native tool body mesh (2,880,084), normal map (2,700,911), hub music (2,614,923) and Crusher scene (2,455,800). These are not evidence files.

## Suspicious names that must remain

- No entries from `docs/`, `tools/`, `tests/`, `archive/`, `qa-results/` or `.github/` exist in the PCK. Export exclusions already prevent repository reports and captured images from becoming game downloads.
- All `scripts/qa/` entries together occupy only 543,599 bytes. `qa_launcher.gd` loads named suites dynamically from the requested DEV startup flag. No removal is justified from ordinary startup's lack of QA activity.
- The two native `report.json` files total 1,461,755 bytes. `native_worn_visual._start()` selects `baked_response`; `native_rig.configure()` reads `component-response/report.json`, verifies its response image and verifies the SHA-256 of `transfer-albedo/report.json`. They are active identity inputs, despite their historical report names.
- `candidate.json`, `runtime-scene.json`, raw albedo/normal/ORM/cloth textures, `tasks.json` and `motion.json` are likewise used and identity-checked. Removing raw textures because an imported texture exists elsewhere would break this path.
- The 72.23 MB hero atlas group is still actively requested by `hero_gear._begin_load()`. Gear paths are built dynamically for eleven tools, four directions, cloth masks and worn motion banks. `player_visual` uses this route for native fallback and the non-native drill tools; `outfit_preview.configure()` also uses those atlases for wardrobe previews. Saved cosmetic IDs still resolve through `hero_gear.resolve_tool()`. Their continued presence is required by current code.
- Raw Treasury PNGs are intentionally read with `Image.load_from_file()` in `treasury_room.texture()`. Their raw format is not itself accidental export duplication.

The old `assets/characters/outfits` group alone accounts for 24,066,598 bytes. Its old miner atlas names are a possible future asset-retirement investigation, but current textual absence is not complete scene/compiled-code/dynamic-path proof. Similarly, the old west-oriented `vault-exit-v1.png` (2,080,568 bytes) has been superseded in the current Treasury construction by `vault-exit-east-v2.png`. Neither is approved for removal by this review. Retiring historical art requires explicit dependency closure and relevant appearance/DEV compatibility checks, not a last-minute wildcard exclusion.

## Quantified cleanup candidates and narrow proof route

There are eight byte-identical groups. Keeping one physical copy per group could save **1,790,639 bytes, 0.55% of the PCK** before alignment: 1,715,012 bytes of cloth-mask copies under different legitimate import paths, plus 75,627 bytes for the identical `visual_capture_driver.gd`/`visual_capture_driver_integrated.gd` source. No large duplicate scene, audio or raw-image group was found.

If this small saving is pursued later, the least invasive route is physical payload deduplication while preserving every virtual path, its byte length and its digest. A disposable pack can point identical entries to the same retained payload. Acceptance must compare the complete path-to-SHA-256 manifest, read every aliased path through Godot, and retain the existing ordinary startup and affected appearance gates. This changes packaging only; it requires no asset, dynamic path, save-format or gameplay-source removal. It is not worth introducing a new pack-writing behavior into the current final wave for a 0.55% saving.

An additional 42 compiled script entries, totalling 1,165,048 bytes, are no longer the targets of their source remaps. They are potential historical overlay residue, not proven unreachable resources. Before pruning, resolve scene/UID/direct resource references and DEV loads against the exact package, then verify all retained resource bytes and the named startup modes. This is at most another 0.36% and remains deferred. It overlaps the QA category above and must not be added to that category as a separate saving.

No runtime test, asset conversion, deletion, source edit, export or publication was performed for this audit. Package footprint remains a future startup-budget concern; this review found no basis for claiming a startup or FPS improvement.

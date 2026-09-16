# Menu touch sections — 16 September 2026

Based on `ec8976622231bc70c5413775291e841d0e543353`, in the separate
`codex/menu-touch-sections-20260916` worktree. Only the QA script and this report
change. No gameplay, fixtures, gesture generation, browser acknowledgement,
timing, assertions or visual assets were changed.

`--menu-touch-section=` accepts `all`, `pause`, `wardrobe`, `light`, `lists`,
`starforge`, or `workshops`. Omitting it means `all`, in the original order below.
Unknown, empty, bare or repeated selector arguments fail before starting a
section, print `EVER_DEEPER_MENU_TOUCH_ARGUMENT_FAILED`, retain the existing
gameplay failure summary, and exit 4 through the existing driver.

| Section | Existing coverage | Native checks |
| --- | --- | ---: |
| pause | Pause/settings modal blocks underlying Starforge input | 5 |
| wardrobe | Unlock, wear, preview, save reload, portrait release | 26 |
| light | Physical preview, upgrade, equip, save reload, viewport release | 25 |
| lists | Pet skills, inventory and achievements | 10 |
| starforge | Fixed cards, preview, cancellation and deliberate purchase | 31 |
| workshops | Long catalogs, browsing/taps, details and available dev tools | 26 |
| **Total** | **All original source touch assertions** | **123** |

Each section emits these JSON markers around its existing test body:

```text
EVER_DEEPER_MENU_TOUCH_SECTION_BEGIN {"section":"pause"}
EVER_DEEPER_MENU_TOUCH_SECTION_COMPLETE {"section":"pause","checks":5,"failures":[]}
```

`checks` is the section's count, and `failures` contains its new failure labels.
The existing `EVER_DEEPER_OVERHAUL_GAMEPLAY_OK/FAILED` final marker remains.
Browser acknowledgements still add one check per gesture, including captures.
The original conditional details/dev-tools assertions remain unchanged: this
headless source run has no developer menu, while an exported DEV build can add
those checks. Do not hard-code 123 as the browser total.

Godot `4.7.2.stable.official.ed1daf0bf`, isolated save directories, serialized
headless processes, 120-second cap each:

- Default and explicit `all`: pass, 123 checks each, all six marker pairs in order.
- Every section independently: pass, exactly the corresponding counts above;
  independent sum is 123. No runtime/parse errors or timeouts.
- Unknown, empty, bare and duplicate selectors: all four expected rejections
  passed, exit 4, zero tests/section starts, explicit failure summaries retained.
- Exact source-body comparisons against the base preserve all helpers and
  assertion bodies; the workshops extraction only introduces local panel/carousel
  declarations. `git diff --check` passes.
- `tools/check_invariants.py` retains an **inherited failure** for
  `scripts/player/player_visual.gd`. Its working SHA-256 is identical to
  `ec89766`: `ba3a54fc83efa883b4a68de7a032e334cb885bcb50427859fc85fdb2a5be2520`.
  The older manifest expects `ba50a787db08620fde3a2da7a44305406fff0a442c82cbea64a061a7146f5fc4`.
  Neither file nor invariant manifest was changed by this task.

Reproduce the unchanged default entry through the standard runner:

```sh
python3 tools/qa.py --godot "$GODOT_BIN" --cases touch --jobs 1 --output /tmp/menu-touch-default
```

Run each selectable section directly with a fresh save location:

```sh
for section in pause wardrobe light lists starforge workshops; do
  XDG_DATA_HOME="$(mktemp -d)" "$GODOT_BIN" --headless --path . -- \
    --visual-capture-suite --menu-touch-only --visual-capture-auto-ack \
    "--menu-touch-section=$section"
done
```

The retained task evidence is
`/workspace/scratch/4e99473f21fc/menu-touch-sections-evidence-c1/`: complete logs,
`results.json`, the serial reproduction runner, assertion-body comparison, and
the inherited invariant failure with base/source hashes. No failed attempt was
discarded. Script SHA-256:
`4e78735b4e856c04fae426985f0909fb57aeda1d0f395b01a7bd70709fbefb81`.

This is native source QA evidence. Immutable browser package jobs, trusted-input
acknowledgements and their CI matrix are handled separately; they have not been
claimed as passing here. No visual or device-performance acceptance is implied.

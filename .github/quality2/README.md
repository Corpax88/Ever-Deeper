# DEV15.56 scoped quality pass

This pass starts from the exact published DEV15.55 distribution, source
`befb9eabfc1ff424fe20c4db34eeea19cc8b0301`, artifact `11309746162` from accepted
run `37219089950`. The nine baseline files are checked against
`public-before.json`; its 27 identities come directly from the verified
DEV15.55 publication receipt. Historical main is a publication carrier and is
never exported.

`prepare.py ORIGINAL OUT [overrides.json] [production]` preserves every unlisted
PCK payload byte. The candidate changes only the source paths explicitly named
in `overrides.json`, plus the DEV version stamp in `premium_menu.gd`. Data,
assets, engine files and player-save identities remain inherited. The written
PCK is atomically replaced and rehashed from disk after the in-memory payload
comparison.

The QA package copies the unchanged published Skills review into
`scripts/qa/suites/full_quality_base.gd`, then adds this pass's fixture. The
inherited visual notice guard and premium/world fixture repairs retain the
previous accepted assertions and SHA guards. `production` omits every new QA
replacement. Baseline QA is built only for a provenance receipt; there is no
redundant baseline browser lane or runtime recovery job.

The native lane retains all 22 accepted gates regardless of this pass's
override list, then adds Treasury sale reservation and goal routing gates, for
24 required gates. The route tool receives explicit `--route-assertions-only`
in this headless lane; it keeps every assertion and skips only PNG captures.
The separate local rendered route evidence and browser captures cover its
visual states. Five separate Mac
browser lanes retain the broad review, focused review, Ricochet lifecycle,
real input journey and ordinary WebKit startup. The last lane uses the exact
production package with no fixture arguments. All lanes bind the same source
commit and production/QA package identities. Existing runners and fixture were
copied from the accepted pass; new focused checks are added before source
freeze. Actual captured images still require independent inspection.

CI starts only when `.github/quality2/run.json` changes on
`codex/quality2-20261004`, or by explicit workflow dispatch. That sentinel is
created only when the candidate is ready. Routine checkpoints do not launch
the matrix. Browser evidence is split into at most four 28 MiB parts and each
part is uploaded independently under a `quality2-` name. The split step fails
if evidence outgrows the uploaded slots.

`accepted.json` is intentionally absent until the exact run, all reports and
images have been accepted. The publisher requires six report hashes, all
three build receipts, all immutable artifact digests and both nine-file
distribution manifests. It verifies the required native gates, real Apple GPU
browser evidence, ordinary startup, source/run identity and every captured
image before staging. The published bytes come only from the accepted
production artifact. It retains the previous DEV15.55 files as a rollback,
preserves all 18 LIVE/Worn files, checks the Pages size limit and verifies all
27 public hashes after publication. No overall 9.5 score or physical-phone
verification is implied by these automated gates.

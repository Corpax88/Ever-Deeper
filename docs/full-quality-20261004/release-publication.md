# DEV15.55 publication preparation

The publisher promotes the exact accepted `full-quality-production-candidate` artifact. It does not export or rebuild the historical `main` checkout. Publication remains gated by an author-created `.github/full-quality/accepted.json` after the final source, native regressions, browser checks and actual images have been reviewed. No acceptance file is created by this preparation.

The release keeps all nine LIVE files and all nine Worn files byte-identical. Before staging, it downloads and verifies all 27 existing public files. The older Ricochet publication's manifest supplies the unchanged LIVE/Worn and engine hashes; DEV HTML/PCK are explicitly replaced with the verified DEV15.54 baseline identities. The workflow saves the previous DEV and a nine-file rollback manifest, deploys only the accepted nine candidate files, then verifies all 27 public hashes. A failed public verification is recorded as a failed release; it does not silently report success or automatically roll back another deployment.

## Acceptance file

Create this only after the final `Full Ever-Deeper Quality Review` run has succeeded and the actual evidence is accepted. Values below describe the schema, not a ready acceptance:

```json
{
  "schema": 1,
  "accepted": true,
  "images_inspected": true,
  "reviewer": "author",
  "version": "1.0.0-dev.15.55",
  "destination": "dev",
  "source": "<exact 40-character QA run head SHA>",
  "run": 0,
  "artifacts": [
    {"id": 0, "name": "full-quality-production-candidate", "digest": "sha256:<GitHub artifact digest>"}
  ],
  "production_manifest": {},
  "qa_manifest": {},
  "receipt_sha256": {"baseline": "", "candidate": "", "production": ""},
  "report_sha256": {"native": "", "candidate": "", "focused": "", "ricochet-lifecycle": "", "journey": "", "ordinary-candidate": ""}
}
```

Both manifests contain the exact nine `{size, sha256}` entries emitted by `prepare.py`. Receipt hashes bind the original bytes at `full-quality-package-receipts/{baseline,candidate,production}/qa-build-receipt.json`; report hashes bind each original, unedited `report.json`. Bind every required artifact's ID, name and GitHub SHA256 digest from that same run: production candidate, native, package receipts, and each of the five browser groups' `-manifest` plus every `-00`, `-01`, etc. part named in its recovery manifest. Do not include old baseline supplement or runtime artifacts. Artifact names must match exactly; extra or missing parts fail closed.

The publisher checks the run's workflow path, success and source; every artifact's run/source/digest; every production byte; baseline provenance; retained-payload receipts; matching production/QA overrides; absence of new QA replacements in production; native production/QA PCK identity and required gates; all browser checks; actual Apple GPU frames; and ordinary production startup without fixture arguments. Split archives are verified and original reports are read directly without filesystem extraction. Acceptance records visual judgment separately from automatic checks; hosted Mac evidence does not claim a physical iPhone test or an overall 9.5 rating.

Before publishing, download artifacts with their artifact-name directories intact and run `python3 .github/full-quality/publish.py validate ARTIFACTS_DIRECTORY` for offline evidence and package validation. The guarded workflow runs on a new acceptance commit to `main`, or an explicit dispatch on `main`. It never deploys from the development branch and normal publisher/source commits do not trigger publication.

Local publisher validation: Python compilation and workflow YAML parsing passed. A temporary synthetic evidence bundle referencing the real candidate's distribution bytes passed the positive binding route and rejected absent acceptance, mismatched source, changed reviewed report, missing artifact binding, the QA pack offered as production, and a failed native assertion even with an updated report hash. This validates the publication guard, not the game or any final release. No network write, acceptance file or deployment was performed.

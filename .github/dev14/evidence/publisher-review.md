# DEV14 independent publisher source review

**Decision: accepted for the narrow publisher source gate; no concrete blocker identified.** The current revision correctly separates original candidate build provenance from final same-package verification. This review does not claim deployment or successful public verification.

| Inspected file | SHA256 |
|---|---|
| `.github/dev14/publish.py` | `47c8ecf1c73b7f8b9eaad1b2caeb6514f96b996b386bd82ca3b9320926fe5e0c` |
| `.github/workflows/publish-dev14.yml` | `91abe7082d8fce2a277be5caba7f0e72ccc01ffa4ba64955057db2cd59b64688` |

`reviewed()` binds the nine-file manifest, original LIVE/DEV13 baseline, retained-trial manifest and successful final browser report by hash. Final report version/files/source/preceding run must agree with the receipt. The original failed browser report remains hash-bound, must contain the expected resume-observer failure, and must name the same package. Required checks now include resumed real input. The prepared manifest equals the inspected final report's nine file identities.

`prepare()` checks final run `35597706023` is successful at verification commit `8e5b66ef0d81626567275d110bdd09b087e2d6b2`. It independently checks original run `35596622855` has source `9989805a329373af6c19dc5cde21e23205d87ea5` and a successful build job. This permits the honestly retained observer failure without treating the original overall run as successful. Candidate artifact ID/name/source run/digest are checked through the GitHub API; its downloaded manifest and all nine actual file sizes/SHA256s must match the reviewed manifest. The workflow downloads from `artifact_run_id`, not the final verification run.

The unchanged publication boundary verifies the pinned nine LIVE, nine DEV13 and nine retained-trial files before staging. It replaces only ordinary `dev/`, preserves LIVE and `dev/worn/`, permits exactly 27 game files plus `.nojekyll`, rechecks preserved bytes and the site-size limit, and retains verified DEV13 as a 30-day rollback artifact before deployment. Shared Pages concurrency and workflow dependencies retain gate order.

The verifier emits success only after exact size/SHA256 matches for all 27 public game files. A verification failure does not automatically roll back; retained DEV13 remains available. Source inspection cannot substitute for that eventual public receipt.

Final visual/resume evidence is accepted in `evidence/dev14-final/independent-review.{md,json}`. The prepared receipt's visual/publisher booleans were intentionally false while this review was being completed; the parent will bind the final reviews and set those gates. No Actions call, staging, game-suite rerun, export, deployment or public binary fetch was performed by this critic.

# Exact premium DEV publication

This adapter publishes only candidate **10442929350** from source
`c8906f1d46309227344f101a6b0ae7c1a9b1e69b`, successful premium review run
**35088488455**, attempt 1. It never exports, rebuilds, edits the reviewed bytes,
changes the old publishers, or approves a new LIVE release.

`package.json` pins both downloaded ZIPs, every member, source identity and the
complete-report artifact **10443378936**. The gate checks all 12 exact successful
jobs and the complete report's 15 DEV core cases, both flavors, 19 visual cases,
gameplay, six touch sections and native commerce residency. The QA identity's
run ID remains its original review run, independent of the publication run.

`review.json` records Mats's explicit current DEV publication request and the
actual bounded visual and animation readiness. It does not approve final 1.0.
Only `approved_for_dev_playtest` with concrete evidence and no blocking defects
permits staging. No critic score, physical-iPhone claim, historical audio flag,
or final whole-game approval is invented. The current package retains its DEV8
display label; the commit and package hashes identify this premium build.

`baseline.json` pins the existing DEV8 tool-skin publication receipt. Preparation
downloads and checks all 18 current public files before creating a Pages site.
It retains the previous DEV and LIVE bytes plus their receipt in `rollback/`.
The staged root contains the same nine LIVE files, `.nojekyll`, and `dev/` with
exactly the nine candidate files. Metadata and Production candidate files are
excluded. Any changed baseline aborts; do not silently recapture a new baseline.

The workflow follows the existing main-branch publication pattern. Only an
intentional change to its workflow or `review.json` triggers it. Its package
job must successfully upload rollback before uploading/deploying Pages. All
publishers share `pages-ever-deeper` with cancellation disabled. Final verification
checks all 18 public files and retains a JSON receipt, including failures. A
failed final verification does not automatically deploy a second build; the
retained rollback has both original nine-file sets for explicit restoration.

Offline checks (no network, renderer or deployment):

```sh
python3 .github/premium-dev/check_release.py --evidence /absolute/dev-ready-c8906f1
python3 .github/premium-dev/publish.py check-review
```

The second command fails if the readiness record is pending or incomplete.
The fixture checks exercise changed package/baseline bytes, unsafe ZIP members,
missing/cancelled QA jobs, partial reports, unchanged LIVE staging, rollback and
failed public verification. Real ZIPs are extracted and rehashed when `--evidence`
is supplied. Fixture success is not visual review or proof of deployment.

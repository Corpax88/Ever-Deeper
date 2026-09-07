# Ever Deeper 0.46.0 — Little Paws reactions

Publishes the companion journal and gameplay improvements from 0.46.0-dev.1 plus ten new authored petting animations. DEV identifies as 0.46.0-dev.2; production identifies as 0.46.0 and excludes the developer menu resource and control.

Tap the mole inside Together, Paw skills or How we help for a wave, bashful smile, applause, hop, nuzzle, helmet tip, paw-kiss, dance, giggle or hug. All ten appear before repeats. Repeated taps cannot stack animations. Closing the menu restores the original portrait and normal world controls. No economy, skill prices or save schema change accompanies petting.

New production PNGs are in `assets/companion/reactions/` in the complete editable source package. Existing world animation atlases and the original portrait are preserved. Source changes against 0.46.0-dev.1 are in `source.patch`; the complete source package also includes all authored PNGs.

Validation: 859 source gameplay checks; 859 checks in each exact native DEV and production PCK; production build-flavor check confirms menu=false, resource=false, isolated production save namespace. Final browser gameplay and 932×430 visual review are recorded separately in `visual-review.json` before publication.

Distribution: reconstruct exact DEV from the current public DEV baseline, then exact production from that DEV candidate. Every base, delta part, reconstructed PCK, and runtime file is hash-checked. Publication downloads the reviewed Actions artifact, backs up both existing public builds for 30 days, deploys all 18 files atomically, then re-fetches and verifies every public file.

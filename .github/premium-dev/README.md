# DEV9 immutable playtest publication

Source:e76a2b90a8a6da4d2673689ce2eeb646e5c2303b.
QA:35099632983. Version:1.0.0-dev.9.
Publishes only the verified candidate artifact, preserving all nine LIVE files
and retaining both previous web packages for rollback before deploy.
The baseline is the successful c8906f1 public receipt copied to
baseline-c8906f1-receipt.json; do not reuse older DEV8 baseline hashes.

Only the contact-boundary recovery correction and visible DEV identity change
from the previous integrated package. Renderer/corner/wall experiments are
not included. See review.json and package-animation-readiness.json for bounded
acceptance, limitations and the current user authorization.

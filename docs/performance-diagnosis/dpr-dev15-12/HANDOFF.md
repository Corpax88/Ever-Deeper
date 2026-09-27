# DEV15.12 optional DPR controls

User authorized DPR1/2/3 in existing DEV for physical-phone comparison.
Canonical source9e418296ea469c22e33a4308f3c42798a6205b6b on
codex/dpr-dev15-12-20260927. Reuses exact accepted DEV15.11 artifact10925867913,
sourceba396beeed9e587a8dc700edef7b28b79f1095d6; 1416 PCK resources unchanged.
Only developer menu, version and HTML DPR bridge change. None of the rejected
FPS experiments is included. Audio PCM sharing remains byte-identical.

DEV TOOLS has DPR1,2,3 buttons. Default3 on every reload, no save mutation.
Selection starts the existing FPS meter, closes menu and resizes through the
engine's ordinary HiDPI path. Existing report window is flushed before the
change so reported DPR/canvas samples do not mix intentional settings.
Report transport/schema unchanged; physical-phone report not yet verified.

Validation36350821510 passed: real WebKit touches3/2/1/3, canvas AND GL buffer
2328x1260/1552x840/776x420/2328x1260, actual mining after each change,
no context loss, reload remains3. Report10942515789; immutable candidate
10942450947. Root inspected menu plus all three gameplay captures. DPR1 is
visibly coarser, DPR2 softer, DPR3 restores sharpness. This is an explicitly
requested option, no sustained FPS or physical-iPhone claim. Reload observed
from3; reset from other values follows unconditional startup assignment.

Publisher pins exact candidate digest and successful source run, downloads and
hash-verifies existing LIVE9 + Worn9 + oldDEV9 files, replaces only DEV9, retains
rollback and verifies all27 public files. Publication run36351090840 passed package, deploy and verification. Receipt
artifact10942610938 confirms all27 public hashes; LIVE9/Worn9 unchanged.
Published commit e390709a63f897723aa3c7b22d4840a95fb32d9d.
Next: user START REPORT, compare3/2/1/3 in same area,
roughly20–30s each, SEND REPORT. Do not repeat accepted Mac comparison.

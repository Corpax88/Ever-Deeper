# Actual original package versus integrated CPU/native candidate

Source676e122777636c3f5e5e74c9bcc8088827e2e840, run36116139795, completed2026-09-25. OriginalexactDEV15.9c63aabd/run36043919958 versuscandidate981dfb6/run36115911966. Candidate combines world occupancyrevision + guarded native empty2Dcanvas removal, no UI consolidation. Engine/assets/fullresolution/lightstates retained.

TwoMac AppleGPU/WebKit workers, balanced ABBA/BAAB with fresh contexts,30s heldmining warmup then3x15s windows/block. Both48checks/12windows pass,24windows total. Everywindow has activehero, fixedposition, realimpacts and sync4→3perrenderframe. These counts are notGPUtime; wrappers cost samepercall, fewer candidatecalls means totalobservercost differs. Blockwindows correlated. Allwindows retained, nooutlierdeletion.

WeightedFPS45.000→47.513(+5.58%) and34.335→38.402(+11.85%). Worker1 blockFPS40.056orig/39.237cand/55.819cand/49.953orig: substantialdrift and mixed adjacent comparisons; slowframes205→259, worstcandidate321ms. Worker2 block40.275cand/35.644orig/33.030orig/36.527cand; slow598→333, p95mostlybetter. Aggregatebenefit inbothworkers is encouraging, not consistentstutterremoval orphysicalphonefix. Donot treat24windows as24independentreplicates orblindlyrepeatthisunchangedmatrix.

Artifacts10855467666(17255030bytes) and10855570959(17252899bytes), exactsize+ZIPverified. Rawreports/windows/8actualPNGs retained; endimages aredifferentanimationtimes, not fullpackagepixel-exactcomparison. Earlier occupancy/nativeisolations separatelyestablishedpixelparity. Independentreviewpending.

Prior9dd26bf/run36115604760 failedcandidateQAinheritancepathandisnotafullFPSresult; first-failure/report.json preservesactualerror.981usescanonicaldev14_reviewsourcepath; no productioncodechangefrom94f3302.

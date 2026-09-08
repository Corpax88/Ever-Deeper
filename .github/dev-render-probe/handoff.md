# DEV lighting diagnostic handoff

- Version: 0.46.9-dev.5; physical iPhone Air FPS drop remains unresolved.
- Reviewed source: 25216ecf9809914b3b6271fe9b5804620dafa403.
- Final QA: https://github.com/Corpax88/Ever-Deeper/actions/runs/34231779653 — all five jobs passed.
- Candidate artifact: 10058173775, dev-render-probe-candidate; exact nine-file manifest and review in review.json.
- Four final result images visually reviewed; mobile touch, seven stages and restoration verified.
- DEV flow: hub or Depth 2 → DEV TOOLS → AUTO FPS TEST · 2 MIN. Stand still, keep the game visible and capture the final table.
- Original configuration runs for 60 seconds; pet lights, shadows and world lights are then tested separately with restored intervals. The final table includes engine FPS, browser RAF and p95.
- Save and skill values are preserved. Cancel/focus/area changes restore the original light state.
- Engine JS/WASM and normal canvas behavior are unchanged from DEV4.
- Publication prepared; deployment and all-18-file public verification pending. LIVE stays 0.46.9.

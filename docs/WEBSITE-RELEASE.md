# Website publication is part of every Ever-Deeper release

Standing instruction from Mats, 4 October 2026: whenever a new Ever-Deeper update is published, publish its changes on the existing website in the same release task. This applies to both DEV and LIVE releases and does not require a new request from Mats.

Target: https://ever-deeper-game.corpax88.chatgpt.site
Sites project: `appgprj_6abcf3a6e07481918afb1c03f29caec0`.

1. Verify the game publication and current release handoff first. Use the published version, date, actual completed changes and known limits. Never document a candidate or planned change as released.
2. Open the current Site source with the Sites skill. Preserve its audience, design, image gallery, historical records and separate DEV/LIVE links. The Site source is maintained separately from the game repository.
3. Update `content/releases.json`, the matching entry and latest status in `dist/patch-notes.html`, the current release on `dist/index.html`, and the current status in `dist/historien.html`. Add a history milestone when the release warrants one. Use Norwegian copy and date releases in Europe/Oslo. Retain unique release IDs and immutable evidence links.
4. Check local links, release ordering and changed content. Do not rerun the old `content/render_history.py` or `content/build_history.py`: they contain stale snapshots and can erase newer edits. Preserve game and image evidence; do not rebuild or redeploy the game for a website update.
5. Save and publish the existing Site through its supported Sites workflow. Confirm successful deployment, then record the Site source commit, saved version, deployment ID and URL in the release handoff. A release task is not fully finished until the corresponding website update succeeds. If blocked, retain the pending website work and report the blocker accurately without rolling back the verified game release.

This workflow rule is durable in the game repository on main and the current source branch, and in the Site source. New source branches must retain it. It supersedes historical statements that website updates only occur on a separate request.

The available GitHub automation events were checked on 4 October 2026 and support pull requests, not this project's direct publication/workflow completion. No autonomous release webhook or substitute polling task is installed. The publishing agent must perform this step directly; do not promise a background service.

## Latest verified website publication

Game: LIVE1.0.5 promotes DEV15.56; DEV15.56 and Worn preserved. Website source141993fc3db781cd884268d90c0d1377a4cb6a17; saved Site version9; deployment appgdep_6ac2d5b6116c8191a1bbac2d8aa36597 succeeded. URL: https://ever-deeper-game.corpax88.chatgpt.site. 82 release records, preserved gallery/media/styles/scripts,238 local links checked. Browser visual QA not run under managed Sites limitation. Game publication37240619358 / receipt11317322246. Full receipt and continuation: docs/live-1-0-5/HANDOFF.md.


## Latest verified website publication — DEV15.57

Game DEV15.57 and LIVE1.0.5. Website source `eb0dcdf3605497ff7c5ae965c19da1f0a20df283`; saved version10 (`appgprj_6abcf3a6e07481918afb1c03f29caec0~appgver_42f67349eaf88191a90e9b9f05fab97b`); deployment `appgdep_6ac2d7b5df648191af806b5d587e02f2` succeeded 2026-10-04T22:48:38.147591+00:00. URL https://ever-deeper-game.corpax88.chatgpt.site.83 releases,39 preserved gallery steps;241 local links checked; all82 preceding release records unchanged. Assets/styles/scripts/prototype preserved. Browser visual QA not run under the managed Sites limitation; no preview replacement attempted. Game publication37241152216/receipt11316852747 verified all26 hashes (8LIVE,9DEV,9Worn); shared DEV engine contract retained. Release task complete.

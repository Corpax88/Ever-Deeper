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

Game: DEV15.56; LIVE remains1.0.4. Website source: `fbab0a021b8024a41ff35c0c8f213be38fc0fb9b`; saved Site version 8 (`appgprj_6abcf3a6e07481918afb1c03f29caec0~appgver_0e67d18565308191986d25493b959185`); deployment `appgdep_6ac2c8135c7c8191bd0831452e946afc` succeeded at 2026-10-04T21:41:55.157977+00:00. URL: https://ever-deeper-game.corpax88.chatgpt.site. 81 release records, 39 preserved gallery steps; 238 local links and unchanged media/styles/scripts/prototype verified. Browser visual QA not run under the managed Sites limitation. Game publication/evidence: runtime `deaa7088d75d473b0c16951bc05f19c4db7800c4`, publication run37228372436. No game runtime, assets, workflows or published game bytes changed by this documentation step.

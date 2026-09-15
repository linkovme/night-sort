# PROJECT STATE

**Project:** Night Sort  
**Stage:** Milestone 1 — playable Android alpha, retention expansion  
**Engine:** Godot 4.7.2 stable  
**Primary platform:** Android portrait  
**Current playable version:** 0.1.0-alpha

## WORKING
- Fully runnable Godot project.
- Android debug APK is built automatically by GitHub Actions.
- 90-second Normal Shift.
- Deterministic Daily Shift.
- Three destinations using both color and shape.
- Continuous parcel flow with three tappable routing junctions.
- Score, combo, mistakes, difficulty ramp and local best score.
- Two mid-run upgrade choices per shift.
- Six upgrade types with tradeoffs/sidegrades.
- Persistent credits.
- Operations Licenses screen: credits unlock additional upgrade choices.
- Rotating weekly contract with a credit reward.
- Local save data.
- Procedural industrial visuals and custom vector app icon.
- Procedurally generated sound effects and switch haptics.
- Automated Godot smoke test.
- Automated Android debug APK build.

## VERIFIED
- Godot headless import/launch: PASS.
- Android debug export: PASS.
- Successful APK workflow run: https://github.com/linkovme/night-sort/actions/runs/34944190874
- APK artifact name: `night-sort-debug-apk`.

## IN PROGRESS
Milestone 1 expands replayability without making controls more complicated.

## NEXT
1. Add Endless Shift with its own persistent best score.
2. Add parcel modifiers (express / fragile / heavy) with clear visual cues.
3. Expand the upgrade pool while keeping sidegrade philosophy.
4. Add Daily Shift streak and long-term career statistics.
5. Add first-run onboarding and sound/haptic settings.
6. Add ad-service abstraction and exact ad frequency rules without enabling a live ad network yet.
7. Polish balance after device playtesting.
8. Prepare production Android path: Gradle/AAB, target API required by Google Play, release signing, consent/analytics, then live ad SDK.

## KNOWN LIMITATIONS
- This is a real installable alpha, not yet a Play Store production release.
- Live ads are intentionally not connected yet because production ad IDs/account consent configuration do not belong in public source.
- Production signing key and store credentials must never be committed to this public repository.
- No online leaderboard/backend yet.
- Current visual language is cohesive but intentionally minimal; production polish is still ahead.

## RECOVERY RULE
If a chat loses context, read `docs/START_HERE.md` and `docs/NEW_CHAT_PROMPT.md`. Do not reconstruct the project from conversation history.

## LAST DECISION
2026-09-15 — Milestone 0 accepted as a real playable Android alpha after both smoke CI and Android APK export passed.

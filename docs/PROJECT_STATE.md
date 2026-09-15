# PROJECT STATE

**Project:** Night Sort  
**Stage:** Milestone 0 — playable alpha construction  
**Engine:** Godot 4.7.2 stable  
**Primary platform:** Android portrait

## WORKING
- GitHub repository initialized.
- Source-of-truth documentation structure exists.

## IN PROGRESS
- First fully playable local gameplay loop.
- Procedural visual style: no external art dependency for the alpha.
- CI smoke check.

## NEXT
1. Add Godot project skeleton and main scene.
2. Implement routing board, parcels, score/combo/mistakes and difficulty ramp.
3. Implement menu, results, high score and local save.
4. Add a deterministic Daily Shift mode.
5. Add smoke CI and fix all parse/runtime errors it finds.
6. Only after the core loop feels coherent: upgrades, contracts, audio, Android export and ad SDK integration.

## DEFINITION OF FIRST PLAYABLE
A person can open the project, tap Start, understand the goal without a tutorial wall, play a complete run, lose or finish, see a score and replay.

## KNOWN ISSUES
None yet — code is being added.

## LAST DECISION
2026-09-15 — Pin the project to Godot 4.7.2 stable rather than the 4.8 development builds.

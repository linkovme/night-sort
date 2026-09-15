# GAME DESIGN — Night Sort

## Elevator pitch
A one-thumb sorting roguelite. Packages continuously move through a compact conveyor network. The player taps switches to route each package to its matching destination before the night shift collapses into mistakes and jams.

## Design pillars
1. **Understood in seconds.** Tap a junction; watch its arrow change.
2. **Pressure, not complexity.** Difficulty comes from simultaneous traffic and timing.
3. **Short runs, long mastery.** A run is minutes; skill ceiling comes from reading flow and planning ahead.
4. **Systemic longevity.** Seeds, modifiers, upgrades and daily/weekly goals create combinations instead of thousands of hand-made levels.
5. **Respectful mobile design.** No energy system, no forced ad during active play, no fake close buttons.

## Core loop
- A parcel spawns with a clear destination color/symbol.
- It follows the conveyor graph.
- At switch nodes, current switch state chooses the outgoing route.
- Player taps switches to prepare routes.
- Correct delivery: score + combo.
- Wrong delivery: mistake + combo reset.
- Flow gradually speeds up.
- Too many mistakes ends the shift.
- Results screen shows score, best and earned soft currency.

## Alpha rules
- Three destinations: red, blue, green.
- Two meaningful switch junctions.
- 3 allowed mistakes.
- Spawn interval and parcel speed ramp over the run.
- A normal shift is short enough to replay immediately.
- Mouse input mirrors touch for desktop testing.

## Long-term layers
- Run upgrades: choose 1 of 3 after milestones.
- New mechanisms: buffer, scanner, priority gate, fragile parcel, express parcel, temporary outage.
- Daily Shift: same seed for everyone that day.
- Weekly contracts: broad goals that reward normal play.
- Cosmetic warehouse themes and parcel skins.
- Endless mode and leaderboards can come later.

## Fairness rules
- The next parcel must be readable before a reaction is required.
- Random generation may create pressure, never impossible states.
- Destination color always has a secondary shape/symbol cue for accessibility.
- Purchases/ads never improve hidden probability against non-paying players.

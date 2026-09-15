# ARCHITECTURE

## Principle
Keep the first version small, deterministic and easy to recover. Prefer plain GDScript and Godot built-ins over plugins.

## Runtime layout
- `game/scenes/main.tscn` — one bootstrap scene.
- `game/scripts/main.gd` — screen/state coordinator.
- `game/scripts/sort_board.gd` — board simulation, drawing and touch handling.
- `game/scripts/save_store.gd` — tiny local save helper.
- `game/scripts/game_theme.gd` — shared palette/visual constants.

The alpha uses procedural drawing for the board and parcels. This removes art-pipeline dependency while locking a consistent authored look.

## State flow
Menu -> Run -> Results -> Menu/Replay

Daily mode uses a date-derived deterministic seed. Normal mode uses a random seed.

## Persistence
Local save stores only durable player state such as best score, total credits and basic settings. Run state is intentionally disposable in alpha.

## Data later
When upgrade count grows, values move to JSON under `game/data/` and balance can be edited in Google Sheets then exported into Git. Git remains authoritative.

## CI
GitHub Actions launches Godot headless to parse/import the project and run a short smoke launch. Android export gets its own workflow once the gameplay core is stable.

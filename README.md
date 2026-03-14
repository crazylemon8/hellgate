# Hellgate

Portrait-first Godot 4 prototype for the gatekeeper loop.

## Current foundation

- Boot scene that transitions into the main gameplay scene
- One portrait-oriented gameplay lane with a ledge, exits, spawner, player, and enemy container
- Data-driven configs in `data/` for player, skeleton, wave, and round balance
- `GameController` for round flow, score, mistakes, pause, restart, and game-over handling
- `WaveDirector` for spawn cadence and difficulty ramp from resolved skeleton count
- `PlayerController` for movement, sprint drain/recovery, and unified input consumption
- `SortingSkeletonController` for falling, walking, redirects, and exit resolution
- HUD, overlays, and mobile touch controls under `scenes/ui/`

## Project layout

- `scenes/boot/`
- `scenes/game/`
- `scenes/entities/`
- `scenes/ui/`
- `scripts/game/`
- `scripts/entities/`
- `scripts/ui/`
- `data/`
- `assets/`

## Open in Godot

1. Open the repository root as a Godot 4 project.
2. Let Godot re-save imported metadata if it prompts.
3. Run `res://scenes/boot/Bootstrap.tscn`.

## First checks to do in the editor

- Confirm the project opens without scene/script parse errors.
- Verify portrait viewport and top/bottom UI placement.
- Start a round from the start overlay.
- Check keyboard input: `A/D`, `Space`, `Shift`, `P`.
- Check touch UI on a mobile preview or device:
  - joystick returns to neutral
  - sprint button drains and refills the meter
  - pause and retry work without a keyboard

## Likely next polish pass

- Replace placeholder geometry with production art
- Tune spawn, movement, and sprint values in the `.tres` resources
- Add safer mobile-specific visual styling and safe-area padding if device testing shows overlap

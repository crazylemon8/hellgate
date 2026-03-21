# Hellgate

Godot 4.6 gatekeeper prototype with mobile controls, landscape gameplay, and data-driven tuning.

## Current state

- Boot scene that immediately transitions into the gameplay scene
- One landscape-oriented play lane with:
  - a wider visible ledge/platform
  - left/right sorting targets
  - centered player respawn on the ledge
  - skeleton spawning from a center band above the lane
- Start, pause, and retry flow with matching styled overlays
- Single-score HUD with skull-based lives display
- Data-driven balance resources under `data/`
- Keyboard testing support and mobile-first touch controls
- Android export/debug workflow tested locally

## Current gameplay behavior

- Red skeletons should end up on the left
- Green skeletons should end up on the right
- One shared score increases whenever either color reaches the correct exit
- Lives are shown as five skulls; spent lives fade instead of disappearing
- Skeletons spawn with the Phaser-inspired sorting behavior ported into Godot:
  - discrete spawn-rate ramping
  - discrete speed ramping
  - redirect lock timing
  - grounded vs airborne movement differences
- Exit boxes include directional glow/arrow feedback
- Actors only stay grounded while above the visible ledge support area
- Skeletons fall if they move past the ledge edges
- Player falls if they leave the ledge and respawns back at the center spawn point
- Skeletons use split body/skull art with a slight randomized skull wobble
- The slime has jump squash/stretch and speed-based stretch while moving

## Controls

### Desktop

- `A` or `Left Arrow` move left
- `D` or `Right Arrow` move right
- `Space` or `Up Arrow` jump
- `Shift` sprint
- `P` pause

### Mobile

- Fixed-base joystick on the bottom-right
- Upward joystick input triggers jump
- Holding the joystick above the jump threshold keeps jump active so the player jumps again after landing
- Circular sprint button on the bottom-left with a radial sprint meter
- Pause button in the HUD

## Important files

### Scenes

- `scenes/boot/Bootstrap.tscn`
- `scenes/game/GameRoot.tscn`
- `scenes/entities/Player.tscn`
- `scenes/entities/SortingSkeleton.tscn`
- `scenes/ui/TopHUD.tscn`
- `scenes/ui/StartOverlay.tscn`
- `scenes/ui/PauseOverlay.tscn`
- `scenes/ui/GameOverOverlay.tscn`
- `scenes/ui/TouchControls.tscn`

### Scripts

- `scripts/game/game_controller.gd`
- `scripts/game/wave_director.gd`
- `scripts/game/player_input_state.gd`
- `scripts/entities/player_controller.gd`
- `scripts/entities/sorting_skeleton_controller.gd`
- `scripts/ui/circular_meter.gd`
- `scripts/ui/hud_controller.gd`
- `scripts/ui/mobile_controls_controller.gd`

### Data

- `data/game_balance.tres`
- `data/player_config.tres`
- `data/skeleton_config.tres`
- `data/wave_config.tres`

## Open in Godot

1. Open the repository root as a Godot 4.6 project.
2. Let Godot import/update metadata if prompted.
3. Run `res://scenes/boot/Bootstrap.tscn`.

## Current test checklist

- Confirm the project opens without parse/runtime errors
- Verify the landscape HUD fits cleanly on desktop and device
- Start a round and verify:
  - keyboard movement and sprint work
  - mobile joystick activates reliably
  - radial sprint button is visible and reachable
  - player can redirect wrong-way skeletons
  - correct-way skeletons are pass-through
  - actors fall when leaving the ledge bounds
  - player respawns to the center of the ledge after falling off-screen
  - score increments on correct exits
  - skull lives fade correctly when mistakes happen
  - exit markers show directional motion/glow
  - slime jump/stretch and skeleton skull wobble feel subtle but visible

## Android device testing

### Prerequisites

- Godot 4.6 export templates installed
- Android Studio installed
- Java SDK path configured in Godot
- Android SDK / Platform Tools / Build Tools installed
- `adb` available
- Android export preset created and marked runnable

### Typical flow

1. Connect Android phone with USB debugging enabled
2. Confirm the device is visible with `adb devices`
3. Run from Godot to deploy to the device or export an APK when needed

## Current gaps / next polish

- Further tune joystick thresholds, sprint feel, and slime movement feedback
- Improve safe-area handling and HUD spacing across more device shapes
- Add stronger visual feedback for redirects, scoring, and mistakes
- Continue replacing placeholder/world-art blocks with richer production visuals

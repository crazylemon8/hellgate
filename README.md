# Hellgate

Godot 4.6 gatekeeper prototype with mobile controls, landscape gameplay, and data-driven tuning.

## Current state

- Branded startup flow with:
  - custom engine boot splash art
  - minimal `HELLGATE` logo + breathing slime intro
  - clean fade into gameplay
- One landscape-oriented play lane with:
  - a wider visible ledge/platform
  - left/right sorting targets
  - centered player respawn on the ledge
  - skeleton spawning from a center band above the lane
- Start, pause, and retry flow with matching styled overlays
- First-run tutorial flow that teaches:
  - push red left
  - push green right
  - sprint
  - jump
- Single-score HUD with skull-based lives display
- Pause overlay with direct `Music` and `SFX` toggles
- Lucide-based icon set across HUD, pause, and touch controls
- Audio coverage for startup, UI, gameplay feedback, and background music
- Data-driven balance resources under `data/`
- Keyboard testing support and mobile-first touch controls
- Android export/debug workflow tested locally

## Current gameplay behavior

- Red skeletons should end up on the left
- Green skeletons should end up on the right
- One shared score increases whenever either color reaches the correct exit
- Lives are shown as five skulls; spent lives fade instead of disappearing
- Spent skull lives play a white dust poof instead of reflowing the HUD
- Correct sorts pulse the score and exit glow; mistakes trigger a screen flash and failure glow
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
- Pause overlay contains icon toggles for music and SFX that persist locally

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

- `scripts/game/bootstrap.gd`
- `scripts/game/audio_manager.gd`
- `scripts/game/game_controller.gd`
- `scripts/game/save_state.gd`
- `scripts/game/wave_director.gd`
- `scripts/game/player_input_state.gd`
- `scripts/entities/player_controller.gd`
- `scripts/entities/sorting_skeleton_controller.gd`
- `scripts/ui/circular_meter.gd`
- `scripts/ui/hud_controller.gd`
- `scripts/ui/mobile_controls_controller.gd`
- `scripts/ui/tutorial_overlay_controller.gd`

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
- Verify the startup splash/logo-and-slime intro is centered on desktop and device
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
  - skull-loss poof dust plays without layout shifting
  - exit markers show directional motion/glow
  - redirect hits, success pulses, and mistake flashes feel readable
  - slime jump/stretch and skeleton skull wobble feel subtle but visible
  - tutorial runs only once on first launch and then hands off into a fresh round
  - pause-screen music and SFX toggles work and persist across relaunch
  - gameplay music and key interaction sounds are balanced on device

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
- Tune audio mix levels across splash, music, UI, and gameplay cues
- Continue replacing placeholder/world-art blocks with richer production visuals

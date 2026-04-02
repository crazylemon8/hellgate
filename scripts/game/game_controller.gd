extends Node2D
class_name GameController

signal score_changed(total_score: int, mistakes_remaining: int)
signal pause_changed(is_paused: bool)
signal game_over(final_state: Dictionary)

enum RoundState {
	BRIEFING,
	TUTORIAL,
	RUNNING,
	PAUSED,
	GAME_OVER,
}

enum TutorialStep {
	NONE,
	SORT_RED,
	SORT_GREEN,
	USE_SPRINT,
	USE_JUMP,
	COMPLETE,
}

@export var game_balance: GameBalanceConfig
@export var player_config: PlayerConfig
@export var skeleton_config: SkeletonConfig
@export var wave_config: WaveConfig
@export var skeleton_scene: PackedScene

@onready var player: PlayerController = $World/Entities/Player
@onready var enemies: Node2D = $World/Entities/Enemies
@onready var background: ColorRect = $World/Background
@onready var edge_vignette: ColorRect = $World/EdgeVignette
@onready var top_haze: ColorRect = $World/TopHaze
@onready var playfield: ColorRect = $World/Playfield
@onready var playfield_shadow: ColorRect = $World/PlayfieldShadow
@onready var left_wall_shadow: ColorRect = $World/LeftWallShadow
@onready var right_wall_shadow: ColorRect = $World/RightWallShadow
@onready var sky_glow: ColorRect = $World/SkyGlow
@onready var exit_ambient_glow: ColorRect = $World/ExitAmbientGlow
@onready var lane_highlight: ColorRect = $World/LaneHighlight
@onready var tile_strip_a: ColorRect = $World/TileStripA
@onready var tile_strip_b: ColorRect = $World/TileStripB
@onready var tile_strip_c: ColorRect = $World/TileStripC
@onready var ledge_aura: ColorRect = $World/LedgeAura
@onready var ledge: StaticBody2D = $World/Ledge
@onready var ledge_collision: CollisionShape2D = $World/Ledge/CollisionShape2D
@onready var ledge_visual: ColorRect = $World/LedgeVisual
@onready var ledge_highlight: ColorRect = $World/LedgeHighlight
@onready var ledge_body_visual: ColorRect = $World/LedgeBody
@onready var ledge_shadow_visual: ColorRect = $World/LedgeShadow
@onready var left_exit: Marker2D = $World/ExitMarkers/LeftExit
@onready var right_exit: Marker2D = $World/ExitMarkers/RightExit
@onready var left_exit_visual: ColorRect = $World/LeftExitVisual
@onready var right_exit_visual: ColorRect = $World/RightExitVisual
@onready var left_exit_glow: ColorRect = $World/LeftExitGlow
@onready var right_exit_glow: ColorRect = $World/RightExitGlow
@onready var spawner: Marker2D = $World/Spawner
@onready var wave_director: WaveDirector = $WaveDirector
@onready var hud: HudController = $UI/TopHUD
@onready var mobile_controls: MobileControlsController = $UI/MobileControls
@onready var start_overlay: Control = $UI/StartOverlay
@onready var pause_overlay: Control = $UI/PauseOverlay
@onready var game_over_overlay: Control = $UI/GameOverOverlay
@onready var tutorial_overlay: TutorialOverlayController = $UI/TutorialOverlay
@onready var audio_manager: AudioManager = $AudioManager
@onready var feedback_flash: ColorRect = $UI/FeedbackFlash
@onready var start_backdrop: Control = $UI/StartOverlay/Backdrop
@onready var start_button: Button = $UI/StartOverlay/CenterContainer/Panel/VBoxContainer/StartButton
@onready var resume_button: Button = $UI/PauseOverlay/CenterContainer/Panel/VBoxContainer/ActionsRow/ResumeButton
@onready var pause_restart_button: Button = $UI/PauseOverlay/CenterContainer/Panel/VBoxContainer/ActionsRow/RestartButton
@onready var pause_music_button: Button = $UI/PauseOverlay/CenterContainer/Panel/VBoxContainer/SettingsRow/MusicButton
@onready var pause_sfx_button: Button = $UI/PauseOverlay/CenterContainer/Panel/VBoxContainer/SettingsRow/SfxButton
@onready var pause_music_icon: TextureRect = $UI/PauseOverlay/CenterContainer/Panel/VBoxContainer/SettingsRow/MusicButton/Icon
@onready var pause_sfx_icon: TextureRect = $UI/PauseOverlay/CenterContainer/Panel/VBoxContainer/SettingsRow/SfxButton/Icon
@onready var game_over_summary: Label = $UI/GameOverOverlay/CenterContainer/Panel/VBoxContainer/MarginContainer/Content/SummaryLabel
@onready var game_over_retry_button: Button = $UI/GameOverOverlay/CenterContainer/Panel/VBoxContainer/RetryButton

var _mobile_input := PlayerInputState.new()
var _player_spawn_position: Vector2
var _round_state: RoundState = RoundState.BRIEFING
var _red_sorted: int = 0
var _green_sorted: int = 0
var _mistakes_remaining: int = 0
var _resolved_count: int = 0
var _redirect_contact_radius: float = 74.0
var _push_block_radius: float = 42.0
var _actor_floor_offset: float = 10.0
var _tutorial_step: TutorialStep = TutorialStep.NONE
var _tutorial_sprint_progress: float = 0.0
var _tutorial_finishing: bool = false


func _ready() -> void:
	assert(game_balance != null, "Game balance config is required.")
	assert(player_config != null, "Player config is required.")
	assert(skeleton_config != null, "Skeleton config is required.")
	assert(wave_config != null, "Wave config is required.")
	assert(skeleton_scene != null, "Skeleton scene is required.")

	_apply_landscape_layout()
	player.setup(player_config)
	player.floor_y = _get_actor_floor_y()
	_player_spawn_position = player.global_position
	var support_bounds := _get_support_bounds()
	player.set_support_bounds(support_bounds.x, support_bounds.y)
	player.speed_meter_changed.connect(_on_player_speed_meter_changed)
	player.jumped.connect(_on_player_jumped)
	player.jumped.connect(func() -> void:
		audio_manager.play_jump()
	)
	player.landed.connect(func() -> void:
		audio_manager.play_land()
	)
	player.sprint_started.connect(func() -> void:
		audio_manager.play_sprint()
	)
	player.respawned.connect(func() -> void:
		audio_manager.play_respawn()
	)
	wave_director.spawn_skeleton.connect(_on_spawn_skeleton_requested)
	wave_director.configure(wave_config)
	hud.pause_requested.connect(_on_pause_requested)
	mobile_controls.input_changed.connect(_on_mobile_input_changed)
	start_button.pressed.connect(func() -> void:
		audio_manager.play_ui_click()
		begin_round()
	)
	start_backdrop.gui_input.connect(_on_start_overlay_input)
	start_overlay.gui_input.connect(_on_start_overlay_input)
	resume_button.pressed.connect(func() -> void:
		audio_manager.play_ui_click()
		_on_resume_requested()
	)
	pause_restart_button.pressed.connect(func() -> void:
		audio_manager.play_ui_click()
		restart_round()
	)
	pause_music_button.pressed.connect(_on_pause_music_toggled)
	pause_sfx_button.pressed.connect(_on_pause_sfx_toggled)
	game_over_retry_button.pressed.connect(func() -> void:
		audio_manager.play_ui_click()
		restart_round()
	)
	score_changed.connect(hud.set_score)
	pause_changed.connect(hud.set_paused)
	audio_manager.music_setting_changed.connect(_sync_pause_audio_buttons)
	audio_manager.sfx_setting_changed.connect(func(_is_enabled: bool) -> void:
		_sync_pause_audio_buttons()
	)
	_sync_pause_audio_buttons()
	audio_manager.play_music()
	if SaveState.is_tutorial_completed():
		_show_briefing()
	else:
		_begin_tutorial()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_apply_landscape_layout()
		player.floor_y = _get_actor_floor_y()
		_player_spawn_position = Vector2(ledge.position.x, _get_actor_floor_y() + 10.0)
		player.set_support_bounds(_get_support_bounds().x, _get_support_bounds().y)


func _unhandled_input(event: InputEvent) -> void:
	if _round_state == RoundState.BRIEFING and _should_begin_from_input(event):
		begin_round()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("pause"):
		match _round_state:
			RoundState.RUNNING:
				set_paused(true)
			RoundState.PAUSED:
				set_paused(false)
			RoundState.GAME_OVER:
				restart_round()


func _physics_process(delta: float) -> void:
	if _round_state != RoundState.RUNNING and _round_state != RoundState.TUTORIAL:
		player.apply_input(PlayerInputState.new())
		return

	var player_input := _build_player_input()
	player.apply_input(player_input)
	_process_redirect_contacts()
	_respawn_player_if_needed()
	if _round_state == RoundState.TUTORIAL:
		_process_tutorial_progress(player_input, delta)


func begin_round() -> void:
	for enemy in enemies.get_children():
		enemy.queue_free()

	_red_sorted = 0
	_green_sorted = 0
	_resolved_count = 0
	_mistakes_remaining = game_balance.allowed_mistakes
	_round_state = RoundState.RUNNING

	start_overlay.visible = false
	tutorial_overlay.hide_overlay()
	pause_overlay.visible = false
	game_over_overlay.visible = false
	_mobile_input = PlayerInputState.new()
	mobile_controls.reset_input()
	player.reset_for_round()
	player.global_position = _player_spawn_position
	wave_director.start_round()
	_set_gameplay_frozen(false)

	score_changed.emit(_red_sorted + _green_sorted, _mistakes_remaining)
	pause_changed.emit(false)


func restart_round() -> void:
	begin_round()


func set_paused(should_pause: bool) -> void:
	if should_pause and _round_state == RoundState.RUNNING:
		_round_state = RoundState.PAUSED
		pause_overlay.visible = true
		_set_gameplay_frozen(true)
		pause_changed.emit(true)
		return

	if not should_pause and _round_state == RoundState.PAUSED:
		_round_state = RoundState.RUNNING
		pause_overlay.visible = false
		_set_gameplay_frozen(false)
		pause_changed.emit(false)


func resolve_mobile_input(input_state: PlayerInputState) -> void:
	_mobile_input = input_state.duplicate()


func _build_player_input() -> PlayerInputState:
	var state := PlayerInputState.new()
	var desktop_axis := Input.get_axis("move_left", "move_right")
	state.move_x = _choose_axis(desktop_axis, _mobile_input.move_x)
	state.jump_pressed = Input.is_action_just_pressed("jump") or _mobile_input.jump_pressed
	state.sprint_held = Input.is_action_pressed("sprint") or _mobile_input.sprint_held
	state.pause_pressed = Input.is_action_just_pressed("pause") or _mobile_input.pause_pressed
	_mobile_input.pause_pressed = false
	return state


func _on_spawn_skeleton_requested(color_name: String, spawn_position: Vector2) -> void:
	_spawn_skeleton(color_name, spawn_position)


func _spawn_skeleton(color_name: String, spawn_position: Vector2) -> SortingSkeletonController:
	var skeleton := skeleton_scene.instantiate() as SortingSkeletonController
	enemies.add_child(skeleton)
	skeleton.global_position = spawn_position
	skeleton.floor_y = _get_actor_floor_y()
	skeleton.setup(skeleton_config, color_name, _resolved_count)
	var viewport_size := get_viewport_rect().size
	skeleton.set_exit_bounds(-48.0, viewport_size.x + 48.0, viewport_size.x * 0.5, viewport_size.y + 96.0)
	var support_bounds := _get_support_bounds()
	skeleton.set_support_bounds(support_bounds.x, support_bounds.y)
	skeleton.exited.connect(_on_skeleton_exited)
	skeleton.resolved.connect(_on_skeleton_resolved)
	skeleton.redirected.connect(func() -> void:
		audio_manager.play_redirect()
	)
	return skeleton


func _on_skeleton_exited(side: String, color_name: String) -> void:
	if _round_state == RoundState.TUTORIAL:
		_handle_tutorial_skeleton_exit(side, color_name)
		return

	var was_correct := (color_name == "red" and side == "left") or (color_name == "green" and side == "right")
	if was_correct:
		if color_name == "red":
			_red_sorted += 1
		else:
			_green_sorted += 1
		audio_manager.play_success()
		hud.pulse_score()
		_pulse_exit(side, true)
	else:
		_mistakes_remaining -= 1
		audio_manager.play_mistake()
		_pulse_exit(side, false)
		_flash_mistake()

	score_changed.emit(_red_sorted + _green_sorted, _mistakes_remaining)
	if _mistakes_remaining <= 0:
		_round_state = RoundState.GAME_OVER
		wave_director.stop_round()
		_set_gameplay_frozen(true)
		pause_overlay.visible = false
		game_over_overlay.visible = true
		var total_resolved := _resolved_count + 1
		var final_score := _red_sorted + _green_sorted
		game_over_summary.text = "Too many souls slipped through. Hold the line again.\n\nFinal score: %d" % [final_score]
		audio_manager.play_game_over()
		game_over.emit(
			{
				"red_sorted": _red_sorted,
				"green_sorted": _green_sorted,
				"resolved_count": total_resolved,
			}
		)


func _on_skeleton_resolved() -> void:
	if _round_state == RoundState.TUTORIAL:
		return

	_resolved_count += 1
	wave_director.on_skeleton_resolved(_resolved_count)


func _on_player_speed_meter_changed(_current_ratio: float) -> void:
	mobile_controls.set_sprint_ratio(_current_ratio)


func _on_pause_requested() -> void:
	if _round_state == RoundState.RUNNING:
		audio_manager.play_ui_toggle()
		set_paused(true)
	elif _round_state == RoundState.PAUSED:
		audio_manager.play_ui_toggle()
		set_paused(false)


func _on_resume_requested() -> void:
	set_paused(false)


func _on_pause_music_toggled() -> void:
	audio_manager.play_ui_click()
	audio_manager.set_music_enabled(not audio_manager.is_music_enabled())
	if audio_manager.is_music_enabled():
		audio_manager.play_music()


func _on_pause_sfx_toggled() -> void:
	var next_value := not audio_manager.is_sfx_enabled()
	if next_value:
		audio_manager.set_sfx_enabled(true)
		audio_manager.play_ui_click()
	else:
		audio_manager.play_ui_click()
		audio_manager.set_sfx_enabled(false)


func _sync_pause_audio_buttons(_unused: bool = false) -> void:
	var enabled_button := Color(0.984314, 0.52549, 0.196078, 1.0)
	var disabled_button := Color(0.254902, 0.101961, 0.0705882, 0.82)
	var enabled_icon := Color(1.0, 1.0, 1.0, 1.0)
	var disabled_icon := Color(1.0, 1.0, 1.0, 0.35)

	var music_on := audio_manager.is_music_enabled()
	pause_music_button.self_modulate = enabled_button if music_on else disabled_button
	pause_music_icon.modulate = enabled_icon if music_on else disabled_icon

	var sfx_on := audio_manager.is_sfx_enabled()
	pause_sfx_button.self_modulate = enabled_button if sfx_on else disabled_button
	pause_sfx_icon.modulate = enabled_icon if sfx_on else disabled_icon


func _on_mobile_input_changed(input_state: PlayerInputState) -> void:
	resolve_mobile_input(input_state)


func _on_player_jumped() -> void:
	if _round_state == RoundState.TUTORIAL and _tutorial_step == TutorialStep.USE_JUMP:
		_advance_tutorial(TutorialStep.COMPLETE)


func _on_start_overlay_input(event: InputEvent) -> void:
	if _round_state != RoundState.BRIEFING:
		return

	if event is InputEventScreenTouch and event.pressed:
		audio_manager.play_ui_click()
		begin_round()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		audio_manager.play_ui_click()
		begin_round()


func _show_briefing() -> void:
	for enemy in enemies.get_children():
		enemy.queue_free()

	_red_sorted = 0
	_green_sorted = 0
	_resolved_count = 0
	_mistakes_remaining = game_balance.allowed_mistakes
	_round_state = RoundState.BRIEFING
	wave_director.stop_round()
	start_overlay.visible = true
	tutorial_overlay.hide_overlay()
	pause_overlay.visible = false
	game_over_overlay.visible = false
	_mobile_input = PlayerInputState.new()
	mobile_controls.reset_input()
	player.reset_for_round()
	player.global_position = _player_spawn_position
	_set_gameplay_frozen(true)
	score_changed.emit(_red_sorted + _green_sorted, _mistakes_remaining)
	pause_changed.emit(false)


func _begin_tutorial() -> void:
	for enemy in enemies.get_children():
		enemy.queue_free()

	_round_state = RoundState.TUTORIAL
	_red_sorted = 0
	_green_sorted = 0
	_resolved_count = 0
	_mistakes_remaining = game_balance.allowed_mistakes
	_tutorial_step = TutorialStep.NONE
	_tutorial_sprint_progress = 0.0
	_tutorial_finishing = false
	wave_director.stop_round()
	start_overlay.visible = false
	pause_overlay.visible = false
	game_over_overlay.visible = false
	_mobile_input = PlayerInputState.new()
	mobile_controls.reset_input()
	player.reset_for_round()
	player.global_position = _player_spawn_position
	_set_gameplay_frozen(false)
	score_changed.emit(0, _mistakes_remaining)
	pause_changed.emit(false)
	_advance_tutorial(TutorialStep.SORT_RED)


func _advance_tutorial(next_step: TutorialStep) -> void:
	var previous_step := _tutorial_step
	_tutorial_step = next_step
	if previous_step != TutorialStep.NONE and next_step != previous_step:
		audio_manager.play_tutorial_complete()
	match next_step:
		TutorialStep.SORT_RED:
			tutorial_overlay.show_message("Tutorial 1/4", "Red skeletons belong on the left. Push this one left.")
			_spawn_tutorial_skeleton("red")
		TutorialStep.SORT_GREEN:
			tutorial_overlay.show_message("Tutorial 2/4", "Green skeletons belong on the right. Push this one right.")
			_spawn_tutorial_skeleton("green")
		TutorialStep.USE_SPRINT:
			tutorial_overlay.show_message("Tutorial 3/4", "Hold the sprint button while moving to build speed.")
			_tutorial_sprint_progress = 0.0
		TutorialStep.USE_JUMP:
			tutorial_overlay.show_message("Tutorial 4/4", "Push the joystick upward to jump once.")
		TutorialStep.COMPLETE:
			_finish_tutorial()


func _spawn_tutorial_skeleton(color_name: String) -> void:
	for enemy in enemies.get_children():
		enemy.queue_free()
	_spawn_skeleton(color_name, spawner.global_position)


func _handle_tutorial_skeleton_exit(side: String, color_name: String) -> void:
	var was_correct := (color_name == "red" and side == "left") or (color_name == "green" and side == "right")
	if was_correct:
		if _tutorial_step == TutorialStep.SORT_RED:
			_advance_tutorial(TutorialStep.SORT_GREEN)
		elif _tutorial_step == TutorialStep.SORT_GREEN:
			_advance_tutorial(TutorialStep.USE_SPRINT)
	else:
		_spawn_tutorial_skeleton(color_name)


func _process_tutorial_progress(player_input: PlayerInputState, delta: float) -> void:
	if _tutorial_step == TutorialStep.USE_SPRINT:
		if player_input.sprint_held and absf(player_input.move_x) > 0.2:
			_tutorial_sprint_progress += delta
			if _tutorial_sprint_progress >= 0.55:
				_advance_tutorial(TutorialStep.USE_JUMP)
		else:
			_tutorial_sprint_progress = 0.0


func _finish_tutorial() -> void:
	if _tutorial_finishing:
		return

	_tutorial_finishing = true
	tutorial_overlay.show_message("You're ready", "Hold the gate.")
	SaveState.set_tutorial_completed(true)
	await get_tree().create_timer(0.8).timeout
	begin_round()


func _should_begin_from_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.is_action("move_left") or event.is_action("move_right") or event.is_action("jump") or event.is_action("sprint")

	return false


func _choose_axis(desktop_axis: float, mobile_axis: float) -> float:
	return mobile_axis if absf(mobile_axis) > absf(desktop_axis) else desktop_axis


func _set_gameplay_frozen(is_frozen: bool) -> void:
	player.set_physics_process(not is_frozen)
	for enemy in enemies.get_children():
		enemy.set_physics_process(not is_frozen)
	wave_director.set_wave_paused(is_frozen)


func _process_redirect_contacts() -> void:
	for enemy in enemies.get_children():
		var skeleton := enemy as SortingSkeletonController
		if skeleton == null:
			continue
		if skeleton.should_accept_redirect(player.global_position, _redirect_contact_radius):
			skeleton.push_from_player(player.global_position)
			skeleton.play_redirect_feedback()
			player.play_redirect_feedback()
			if skeleton.global_position.distance_to(player.global_position) <= _push_block_radius:
				player.push_back_from(skeleton.global_position.x)


func _get_support_bounds() -> Vector2:
	return Vector2(ledge_body_visual.global_position.x, ledge_body_visual.global_position.x + ledge_body_visual.size.x)


func _get_actor_floor_y() -> float:
	var ledge_shape := ledge_collision.shape as RectangleShape2D
	if ledge_shape == null:
		return player.floor_y

	var ledge_top_y := ledge_collision.global_position.y - (ledge_shape.size.y * 0.5)
	return ledge_top_y - _actor_floor_offset


func _apply_landscape_layout() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return

	var width := viewport_size.x
	var height := viewport_size.y
	var side_margin := maxf(24.0, width * 0.03)
	var field_top := 68.0
	var field_bottom := height - 12.0
	var ledge_width := clampf(width * 0.52, 720.0, 980.0)
	var ledge_center_x := width * 0.5
	var ledge_y := height * 0.72

	background.offset_right = width
	background.offset_bottom = height
	edge_vignette.offset_right = width
	edge_vignette.offset_bottom = height
	playfield.offset_right = width
	playfield.offset_bottom = height
	top_haze.offset_left = 0.0
	top_haze.offset_top = 18.0
	top_haze.offset_right = width
	top_haze.offset_bottom = field_top + 92.0

	playfield_shadow.offset_left = side_margin
	playfield_shadow.offset_top = field_top
	playfield_shadow.offset_right = width - side_margin
	playfield_shadow.offset_bottom = field_bottom
	left_wall_shadow.offset_left = side_margin + 18.0
	left_wall_shadow.offset_top = field_top + 8.0
	left_wall_shadow.offset_right = side_margin + 162.0
	left_wall_shadow.offset_bottom = field_bottom
	right_wall_shadow.offset_left = width - side_margin - 162.0
	right_wall_shadow.offset_top = field_top + 8.0
	right_wall_shadow.offset_right = width - side_margin - 18.0
	right_wall_shadow.offset_bottom = field_bottom

	sky_glow.offset_left = 0.0
	sky_glow.offset_top = field_top - 10.0
	sky_glow.offset_right = width
	sky_glow.offset_bottom = height
	exit_ambient_glow.offset_left = side_margin + 120.0
	exit_ambient_glow.offset_top = field_top + 34.0
	exit_ambient_glow.offset_right = width - side_margin - 120.0
	exit_ambient_glow.offset_bottom = field_top + 180.0

	lane_highlight.offset_left = side_margin + 34.0
	lane_highlight.offset_top = field_top + 20.0
	lane_highlight.offset_right = width - side_margin - 34.0
	lane_highlight.offset_bottom = field_bottom - 18.0

	tile_strip_a.offset_left = side_margin + 8.0
	tile_strip_a.offset_top = field_top + 12.0
	tile_strip_a.offset_right = width - side_margin - 8.0
	tile_strip_a.offset_bottom = tile_strip_a.offset_top + 68.0

	tile_strip_b.offset_left = side_margin + 8.0
	tile_strip_b.offset_top = field_top + 182.0
	tile_strip_b.offset_right = width - side_margin - 8.0
	tile_strip_b.offset_bottom = tile_strip_b.offset_top + 72.0

	tile_strip_c.offset_left = side_margin + 8.0
	tile_strip_c.offset_top = field_top + 376.0
	tile_strip_c.offset_right = width - side_margin - 8.0
	tile_strip_c.offset_bottom = minf(field_bottom - 86.0, tile_strip_c.offset_top + 78.0)

	ledge.position = Vector2(ledge_center_x, ledge_y + 12.0)
	var ledge_half := ledge_width * 0.5
	var ledge_shape := ledge_collision.shape as RectangleShape2D
	if ledge_shape != null:
		ledge_shape.size.x = ledge_width - 24.0

	ledge_visual.offset_left = ledge_center_x - ledge_half
	ledge_visual.offset_top = ledge_y - 2.0
	ledge_visual.offset_right = ledge_center_x + ledge_half
	ledge_visual.offset_bottom = ledge_y + 26.0
	ledge_aura.offset_left = ledge_center_x - ledge_half + 28.0
	ledge_aura.offset_top = ledge_y - 48.0
	ledge_aura.offset_right = ledge_center_x + ledge_half - 28.0
	ledge_aura.offset_bottom = ledge_y + 66.0
	ledge_highlight.offset_left = ledge_center_x - ledge_half + 6.0
	ledge_highlight.offset_top = ledge_y + 1.0
	ledge_highlight.offset_right = ledge_center_x + ledge_half - 6.0
	ledge_highlight.offset_bottom = ledge_y + 7.0

	ledge_body_visual.offset_left = ledge_center_x - ledge_half
	ledge_body_visual.offset_top = ledge_y + 14.0
	ledge_body_visual.offset_right = ledge_center_x + ledge_half
	ledge_body_visual.offset_bottom = ledge_y + 46.0
	ledge_shadow_visual.offset_left = ledge_center_x - ledge_half + 10.0
	ledge_shadow_visual.offset_top = ledge_y + 46.0
	ledge_shadow_visual.offset_right = ledge_center_x + ledge_half - 10.0
	ledge_shadow_visual.offset_bottom = ledge_y + 58.0

	var exit_y := field_top + 118.0
	left_exit.position = Vector2(side_margin + 118.0, exit_y)
	right_exit.position = Vector2(width - side_margin - 118.0, exit_y)
	left_exit_visual.offset_left = left_exit.position.x - 58.0
	left_exit_visual.offset_top = exit_y - 28.0
	left_exit_visual.offset_right = left_exit.position.x + 58.0
	left_exit_visual.offset_bottom = exit_y + 38.0
	right_exit_visual.offset_left = right_exit.position.x - 58.0
	right_exit_visual.offset_top = exit_y - 28.0
	right_exit_visual.offset_right = right_exit.position.x + 58.0
	right_exit_visual.offset_bottom = exit_y + 38.0

	left_exit_glow.offset_left = left_exit.position.x - 52.0
	left_exit_glow.offset_top = exit_y - 22.0
	left_exit_glow.offset_right = left_exit.position.x + 52.0
	left_exit_glow.offset_bottom = exit_y + 32.0
	right_exit_glow.offset_left = right_exit.position.x - 52.0
	right_exit_glow.offset_top = exit_y - 22.0
	right_exit_glow.offset_right = right_exit.position.x + 52.0
	right_exit_glow.offset_bottom = exit_y + 32.0

	spawner.position = Vector2(ledge_center_x, field_top + 92.0)
	player.global_position = Vector2(ledge_center_x, _get_actor_floor_y() + 10.0)


func _respawn_player_if_needed() -> void:
	var viewport_size := get_viewport_rect().size
	if player.global_position.y <= viewport_size.y + 120.0:
		return

	player.respawn_at(_player_spawn_position)


func _pulse_exit(side: String, is_success: bool) -> void:
	var glow := left_exit_glow if side == "left" else right_exit_glow
	if glow == null:
		return

	var target_color := Color(1.0, 0.55, 0.34, 0.42) if is_success else Color(0.95, 0.25, 0.22, 0.34)
	var base_color := Color(0.835294, 0.329412, 0.294118, 0.18) if side == "left" else Color(0.368627, 0.760784, 0.498039, 0.18)
	if side == "right" and is_success:
		target_color = Color(0.55, 0.95, 0.63, 0.42)
	if side == "right" and not is_success:
		target_color = Color(0.95, 0.25, 0.22, 0.34)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(glow, "color", target_color, 0.1)
	tween.tween_property(glow, "color", base_color, 0.22)


func _flash_mistake() -> void:
	if feedback_flash == null:
		return

	feedback_flash.color = Color(0.933333, 0.266667, 0.239216, 0.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(feedback_flash, "color", Color(0.933333, 0.266667, 0.239216, 0.12), 0.08)
	tween.tween_property(feedback_flash, "color", Color(0.933333, 0.266667, 0.239216, 0.0), 0.2)

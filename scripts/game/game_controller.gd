extends Node2D
class_name GameController

signal score_changed(red_sorted: int, green_sorted: int, mistakes_remaining: int)
signal pause_changed(is_paused: bool)
signal game_over(final_state: Dictionary)

enum RoundState {
	BRIEFING,
	RUNNING,
	PAUSED,
	GAME_OVER,
}

@export var game_balance: GameBalanceConfig
@export var player_config: PlayerConfig
@export var skeleton_config: SkeletonConfig
@export var wave_config: WaveConfig
@export var skeleton_scene: PackedScene

@onready var player: PlayerController = $World/Entities/Player
@onready var enemies: Node2D = $World/Entities/Enemies
@onready var left_exit: Marker2D = $World/ExitMarkers/LeftExit
@onready var right_exit: Marker2D = $World/ExitMarkers/RightExit
@onready var wave_director: WaveDirector = $WaveDirector
@onready var hud: HudController = $UI/TopHUD
@onready var mobile_controls: MobileControlsController = $UI/MobileControls
@onready var start_overlay: Control = $UI/StartOverlay
@onready var pause_overlay: Control = $UI/PauseOverlay
@onready var game_over_overlay: Control = $UI/GameOverOverlay
@onready var start_button: Button = $UI/StartOverlay/CenterContainer/Panel/VBoxContainer/StartButton
@onready var resume_button: Button = $UI/PauseOverlay/CenterContainer/Panel/VBoxContainer/ResumeButton
@onready var pause_restart_button: Button = $UI/PauseOverlay/CenterContainer/Panel/VBoxContainer/RestartButton
@onready var game_over_summary: Label = $UI/GameOverOverlay/CenterContainer/Panel/VBoxContainer/MarginContainer/Content/SummaryLabel
@onready var game_over_retry_button: Button = $UI/GameOverOverlay/CenterContainer/Panel/VBoxContainer/RetryButton

var _mobile_input := PlayerInputState.new()
var _player_spawn_position: Vector2
var _round_state: RoundState = RoundState.BRIEFING
var _red_sorted: int = 0
var _green_sorted: int = 0
var _mistakes_remaining: int = 0
var _resolved_count: int = 0


func _ready() -> void:
	assert(game_balance != null, "Game balance config is required.")
	assert(player_config != null, "Player config is required.")
	assert(skeleton_config != null, "Skeleton config is required.")
	assert(wave_config != null, "Wave config is required.")
	assert(skeleton_scene != null, "Skeleton scene is required.")

	player.setup(player_config)
	_player_spawn_position = player.global_position
	player.speed_meter_changed.connect(_on_player_speed_meter_changed)
	wave_director.spawn_skeleton.connect(_on_spawn_skeleton_requested)
	wave_director.configure(wave_config)
	hud.pause_requested.connect(_on_pause_requested)
	mobile_controls.input_changed.connect(_on_mobile_input_changed)
	start_button.pressed.connect(begin_round)
	resume_button.pressed.connect(_on_resume_requested)
	pause_restart_button.pressed.connect(restart_round)
	game_over_retry_button.pressed.connect(restart_round)
	score_changed.connect(hud.set_score)
	pause_changed.connect(hud.set_paused)
	_show_briefing()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		match _round_state:
			RoundState.RUNNING:
				set_paused(true)
			RoundState.PAUSED:
				set_paused(false)
			RoundState.GAME_OVER:
				restart_round()


func _physics_process(_delta: float) -> void:
	if _round_state != RoundState.RUNNING:
		player.apply_input(PlayerInputState.new())
		return

	player.apply_input(_build_player_input())


func begin_round() -> void:
	for enemy in enemies.get_children():
		enemy.queue_free()

	_red_sorted = 0
	_green_sorted = 0
	_resolved_count = 0
	_mistakes_remaining = game_balance.allowed_mistakes
	_round_state = RoundState.RUNNING

	start_overlay.visible = false
	pause_overlay.visible = false
	game_over_overlay.visible = false
	_mobile_input = PlayerInputState.new()
	mobile_controls.reset_input()
	player.reset_for_round()
	player.global_position = _player_spawn_position
	wave_director.start_round()
	_set_gameplay_frozen(false)

	score_changed.emit(_red_sorted, _green_sorted, _mistakes_remaining)
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
	_mobile_input.jump_pressed = false
	_mobile_input.pause_pressed = false
	return state


func _on_spawn_skeleton_requested(color_name: String, spawn_position: Vector2) -> void:
	var skeleton := skeleton_scene.instantiate() as SortingSkeletonController
	enemies.add_child(skeleton)
	skeleton.global_position = spawn_position
	skeleton.setup(skeleton_config, color_name, _resolved_count)
	var viewport_size := get_viewport_rect().size
	skeleton.set_exit_bounds(-48.0, viewport_size.x + 48.0, viewport_size.x * 0.5, viewport_size.y + 96.0)
	skeleton.exited.connect(_on_skeleton_exited)
	skeleton.resolved.connect(_on_skeleton_resolved)


func _on_skeleton_exited(side: String, color_name: String) -> void:
	var was_correct := (color_name == "red" and side == "left") or (color_name == "green" and side == "right")
	if was_correct:
		if color_name == "red":
			_red_sorted += 1
		else:
			_green_sorted += 1
	else:
		_mistakes_remaining -= 1

	score_changed.emit(_red_sorted, _green_sorted, _mistakes_remaining)
	if _mistakes_remaining <= 0:
		_round_state = RoundState.GAME_OVER
		wave_director.stop_round()
		_set_gameplay_frozen(true)
		pause_overlay.visible = false
		game_over_overlay.visible = true
		var total_resolved := _resolved_count + 1
		game_over_summary.text = "Sorted %d red, %d green.\nResolved %d skeletons." % [
			_red_sorted,
			_green_sorted,
			total_resolved,
		]
		game_over.emit(
			{
				"red_sorted": _red_sorted,
				"green_sorted": _green_sorted,
				"resolved_count": total_resolved,
			}
		)


func _on_skeleton_resolved() -> void:
	_resolved_count += 1
	wave_director.on_skeleton_resolved(_resolved_count)


func _on_player_speed_meter_changed(_current_ratio: float) -> void:
	hud.set_speed_ratio(_current_ratio)


func _on_pause_requested() -> void:
	if _round_state == RoundState.RUNNING:
		set_paused(true)
	elif _round_state == RoundState.PAUSED:
		set_paused(false)


func _on_resume_requested() -> void:
	set_paused(false)


func _on_mobile_input_changed(input_state: PlayerInputState) -> void:
	resolve_mobile_input(input_state)


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
	pause_overlay.visible = false
	game_over_overlay.visible = false
	_mobile_input = PlayerInputState.new()
	mobile_controls.reset_input()
	player.reset_for_round()
	player.global_position = _player_spawn_position
	_set_gameplay_frozen(true)
	score_changed.emit(_red_sorted, _green_sorted, _mistakes_remaining)
	pause_changed.emit(false)


func _choose_axis(desktop_axis: float, mobile_axis: float) -> float:
	return mobile_axis if absf(mobile_axis) > absf(desktop_axis) else desktop_axis


func _set_gameplay_frozen(is_frozen: bool) -> void:
	player.set_physics_process(not is_frozen)
	for enemy in enemies.get_children():
		enemy.set_physics_process(not is_frozen)
	wave_director.set_wave_paused(is_frozen)

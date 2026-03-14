extends Node
class_name WaveDirector

signal spawn_skeleton(color_name: String, spawn_position: Vector2)

@export var wave_config: WaveConfig
@export var spawn_anchor_path: NodePath

@onready var _spawn_anchor: Marker2D = get_node_or_null(spawn_anchor_path)

var _rng := RandomNumberGenerator.new()
var _running: bool = false
var _resolved_count: int = 0
var _active_skeletons: int = 0
var _time_until_spawn: float = 0.0


func _ready() -> void:
	_rng.randomize()


func _process(delta: float) -> void:
	if not _running or wave_config == null or _spawn_anchor == null:
		return

	if wave_config.max_active_skeletons > 0 and _active_skeletons >= wave_config.max_active_skeletons:
		return

	_time_until_spawn -= delta
	if _time_until_spawn > 0.0:
		return

	_spawn_one()
	_time_until_spawn = _current_spawn_delay()


func configure(config: WaveConfig) -> void:
	wave_config = config


func start_round() -> void:
	_running = true
	_resolved_count = 0
	_active_skeletons = 0
	_time_until_spawn = wave_config.initial_spawn_delay
	set_process(true)


func stop_round() -> void:
	_running = false
	set_process(false)


func on_skeleton_resolved(resolved_count: int) -> void:
	_active_skeletons = maxi(0, _active_skeletons - 1)
	_resolved_count = resolved_count
	_time_until_spawn = _current_spawn_delay()


func _spawn_one() -> void:
	_active_skeletons += 1
	var color_name := "red" if _rng.randf() < 0.5 else "green"
	var min_spawn_x := _spawn_anchor.global_position.x - (wave_config.spawn_band_width * 0.5)
	var max_spawn_x := _spawn_anchor.global_position.x + (wave_config.spawn_band_width * 0.5)
	var spawn_position := Vector2(_rng.randf_range(min_spawn_x, max_spawn_x), _spawn_anchor.global_position.y)
	spawn_skeleton.emit(color_name, spawn_position)


func _current_spawn_delay() -> float:
	var step_interval := maxi(1, wave_config.difficulty_step_interval)
	var speed_steps := int(floor(float(_resolved_count) / float(step_interval)))
	return maxf(wave_config.minimum_spawn_delay, wave_config.initial_spawn_delay - (speed_steps * wave_config.spawn_delay_step))


func set_wave_paused(is_paused: bool) -> void:
	set_process(not is_paused and _running)

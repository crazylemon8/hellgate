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

	if _active_skeletons >= wave_config.max_active_skeletons:
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


func stop_round() -> void:
	_running = false


func on_skeleton_resolved(resolved_count: int) -> void:
	_active_skeletons = maxi(0, _active_skeletons - 1)
	_resolved_count = resolved_count


func _spawn_one() -> void:
	_active_skeletons += 1
	var color_name := "red" if _rng.randf() < 0.5 else "green"
	spawn_skeleton.emit(color_name, _spawn_anchor.global_position)


func _current_spawn_delay() -> float:
	return maxf(
		wave_config.minimum_spawn_delay,
		wave_config.initial_spawn_delay - (_resolved_count * wave_config.spawn_delay_reduction_per_resolved)
	)

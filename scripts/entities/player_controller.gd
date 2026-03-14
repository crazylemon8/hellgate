extends CharacterBody2D
class_name PlayerController

signal speed_meter_changed(current_ratio: float)

@export var floor_y: float = 682.0

var _config: PlayerConfig
var _input := PlayerInputState.new()
var _sprint_ratio: float = 1.0
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if _config == null:
		return

	if not is_on_floor():
		velocity.y += _gravity * _config.gravity_scale * delta
	else:
		velocity.y = maxf(velocity.y, 0.0)

	if _input.jump_pressed and is_on_floor():
		velocity.y = _config.jump_velocity

	var speed_multiplier := 1.0
	if _input.sprint_held and absf(_input.move_x) > 0.05 and _sprint_ratio > 0.0:
		speed_multiplier = _config.sprint_multiplier
		_sprint_ratio = maxf(0.0, _sprint_ratio - (_config.sprint_drain_per_second * delta))
	else:
		_sprint_ratio = minf(1.0, _sprint_ratio + (_config.sprint_recovery_per_second * delta))

	velocity.x = _input.move_x * _config.move_speed * speed_multiplier
	move_and_slide()

	if global_position.y > floor_y + 600.0:
		global_position.y = floor_y - 60.0
		velocity.y = 0.0

	speed_meter_changed.emit(_sprint_ratio)
	_input.jump_pressed = false


func setup(config: PlayerConfig) -> void:
	_config = config
	_sprint_ratio = config.initial_sprint_ratio
	speed_meter_changed.emit(_sprint_ratio)


func apply_input(next_input: PlayerInputState) -> void:
	_input = next_input.duplicate()


func reset_for_round() -> void:
	velocity = Vector2.ZERO
	if _config != null:
		_sprint_ratio = _config.initial_sprint_ratio
	speed_meter_changed.emit(_sprint_ratio)

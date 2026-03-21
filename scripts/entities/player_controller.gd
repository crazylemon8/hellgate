extends CharacterBody2D
class_name PlayerController

signal speed_meter_changed(current_ratio: float)

@export var floor_y: float = 950.0
@export var front_texture: Texture2D
@export var back_texture: Texture2D
@export var left_texture: Texture2D
@export var right_texture: Texture2D

@onready var body_sprite: Sprite2D = $BodySprite
@onready var shadow: Polygon2D = $Shadow

var _config: PlayerConfig
var _input := PlayerInputState.new()
var _sprint_ratio: float = 1.0
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var _support_left_x: float = -INF
var _support_right_x: float = INF
var _is_sprint_active: bool = false
var _facing := Vector2.RIGHT


func _ready() -> void:
	add_to_group("player")
	_update_visuals()


func _physics_process(delta: float) -> void:
	if _config == null:
		return

	var is_grounded := _is_supported()
	if not is_grounded:
		velocity.y += _gravity * _config.gravity_scale * delta
	else:
		global_position.y = floor_y
		velocity.y = maxf(velocity.y, 0.0)

	if _input.jump_pressed and is_grounded:
		velocity.y = _config.jump_velocity

	var speed_multiplier := 1.0
	_is_sprint_active = absf(_input.move_x) > 0.05 and _input.sprint_held and _sprint_ratio > 0.0

	if _is_sprint_active:
		_sprint_ratio = maxf(0.0, _sprint_ratio - (_config.sprint_drain_per_second * delta))
		if _sprint_ratio <= 0.0:
			_is_sprint_active = false
		else:
			speed_multiplier = _config.sprint_multiplier
	else:
		_sprint_ratio = minf(1.0, _sprint_ratio + (_config.sprint_recovery_per_second * delta))

	velocity.x = _input.move_x * _config.move_speed * speed_multiplier
	global_position += velocity * delta

	if _is_supported():
		global_position.y = floor_y
		velocity.y = 0.0

	_update_facing()
	_update_visuals()
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
	_is_sprint_active = false
	_facing = Vector2.RIGHT
	if _config != null:
		_sprint_ratio = _config.initial_sprint_ratio
	_update_visuals()
	speed_meter_changed.emit(_sprint_ratio)


func push_back_from(contact_x: float, separation: float = 28.0) -> void:
	if global_position.x <= contact_x:
		global_position.x = minf(global_position.x, contact_x - separation)
	else:
		global_position.x = maxf(global_position.x, contact_x + separation)


func set_support_bounds(left_x: float, right_x: float) -> void:
	_support_left_x = left_x
	_support_right_x = right_x


func _is_supported() -> bool:
	return global_position.y >= floor_y and global_position.x >= _support_left_x and global_position.x <= _support_right_x


func respawn_at(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	_is_sprint_active = false
	_facing = Vector2.RIGHT
	_update_visuals()


func _update_facing() -> void:
	var movement := Vector2(_input.move_x, 0.0)
	if movement.length_squared() > 0.0001:
		_facing = Vector2(signf(movement.x), 0.0)
	elif velocity.y < -10.0:
		_facing = Vector2.UP
	elif velocity.y > 30.0:
		_facing = Vector2.DOWN


func _update_visuals() -> void:
	if body_sprite == null:
		return

	if absf(_facing.x) > absf(_facing.y):
		body_sprite.texture = left_texture if _facing.x < 0.0 else right_texture
	elif _facing.y < 0.0:
		body_sprite.texture = back_texture
	else:
		body_sprite.texture = front_texture

	var grounded := _is_supported()
	body_sprite.scale = Vector2(0.9, 0.82) if _is_sprint_active and grounded else Vector2(0.86, 0.86)
	shadow.scale.x = 1.0 if grounded else 0.72
	shadow.modulate.a = 0.18 if grounded else 0.08

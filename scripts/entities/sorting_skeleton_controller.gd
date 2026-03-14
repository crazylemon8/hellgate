extends CharacterBody2D
class_name SortingSkeletonController

signal requested_redirect(by_player_position: Vector2)
signal exited(side: String, color_name: String)
signal resolved

const LEFT := -1
const RIGHT := 1

@export var floor_y: float = 978.0

@onready var body_polygon: Polygon2D = $BodyPolygon
var _config: SkeletonConfig
var _color_name: String = "red"
var _walk_direction: int = RIGHT
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var _left_exit_x: float = 0.0
var _right_exit_x: float = 0.0
var _screen_center_x: float = 0.0
var _bottom_exit_y: float = 0.0
var _exited: bool = false
var _speed_multiplier: float = 1.0
var _redirect_lock_until_usec: int = 0

func _physics_process(delta: float) -> void:
	if _config == null or _exited:
		return

	var is_grounded := global_position.y >= floor_y
	if not is_grounded:
		velocity.y += _gravity * _config.fall_gravity_scale * delta
	else:
		global_position.y = floor_y
		velocity.y = maxf(velocity.y, 0.0)

	velocity.x = _walk_direction * _current_walk_speed()
	global_position += velocity * delta

	if global_position.y >= floor_y:
		global_position.y = floor_y
		velocity.y = 0.0

	if global_position.x <= _left_exit_x:
		_leave("left")
	elif global_position.x >= _right_exit_x:
		_leave("right")
	elif global_position.y >= _bottom_exit_y:
		_leave("left" if global_position.x < _screen_center_x else "right")


func setup(config: SkeletonConfig, color_name: String, resolved_count: int) -> void:
	_config = config
	_color_name = color_name
	_walk_direction = RIGHT if color_name == "red" else LEFT
	velocity = Vector2.ZERO
	_update_visuals()
	apply_difficulty(resolved_count)


func apply_difficulty(resolved_count: int) -> void:
	var step_interval := maxi(1, _config.speed_step_interval)
	var speed_steps := int(floor(float(resolved_count) / float(step_interval)))
	_speed_multiplier = 1.0 + (speed_steps * _config.speed_step_amount)


func set_exit_bounds(left_exit_x: float, right_exit_x: float, screen_center_x: float, bottom_exit_y: float) -> void:
	_left_exit_x = left_exit_x
	_right_exit_x = right_exit_x
	_screen_center_x = screen_center_x
	_bottom_exit_y = bottom_exit_y


func redirect(by_player_position: Vector2) -> void:
	var now_usec := Time.get_ticks_usec()
	if now_usec < _redirect_lock_until_usec or _is_moving_toward_correct_side():
		return

	requested_redirect.emit(by_player_position)
	_walk_direction = RIGHT if global_position.x > by_player_position.x else LEFT
	_redirect_lock_until_usec = now_usec + int(_config.redirect_lock_seconds * 1000000.0)
	velocity.x = _walk_direction * _config.redirect_push_speed * _speed_multiplier
	velocity.y = minf(velocity.y, -120.0)


func _current_walk_speed() -> float:
	var base_speed := _config.grounded_walk_speed if global_position.y >= floor_y else _config.airborne_walk_speed
	return base_speed * _speed_multiplier


func _leave(side: String) -> void:
	if _exited:
		return

	_exited = true
	exited.emit(side, _color_name)
	resolved.emit()
	queue_free()


func _update_visuals() -> void:
	body_polygon.color = Color("#d6544b") if _color_name == "red" else Color("#5ec27f")


func _is_moving_toward_correct_side() -> bool:
	return (_color_name == "red" and _walk_direction == LEFT) or (_color_name == "green" and _walk_direction == RIGHT)


func should_accept_redirect(player_position: Vector2, contact_radius: float) -> bool:
	if _exited or _is_moving_toward_correct_side():
		return false

	return global_position.distance_to(player_position) <= contact_radius


func is_heading_wrong_way() -> bool:
	return not _is_moving_toward_correct_side()


func push_from_player(player_position: Vector2) -> void:
	redirect(player_position)
	if player_position.x < global_position.x:
		global_position.x += 10.0
	else:
		global_position.x -= 10.0

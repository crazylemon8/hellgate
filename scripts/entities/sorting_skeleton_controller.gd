extends CharacterBody2D
class_name SortingSkeletonController

signal requested_redirect(by_player_position: Vector2)
signal exited(side: String, color_name: String)
signal resolved
signal redirected

const LEFT := -1
const RIGHT := 1
const SUPPORT_SNAP_MARGIN := 18.0

@export var floor_y: float = 950.0

@onready var body_sprite: Sprite2D = $BodySprite
@onready var skull_sprite: Sprite2D = $SkullSprite
@onready var shadow: Polygon2D = $Shadow

var _config: SkeletonConfig
var _color_name: String = "red"
var _walk_direction: int = RIGHT
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var _left_exit_x: float = 0.0
var _right_exit_x: float = 0.0
var _screen_center_x: float = 0.0
var _bottom_exit_y: float = 0.0
var _support_left_x: float = -INF
var _support_right_x: float = INF
var _exited: bool = false
var _speed_multiplier: float = 1.0
var _redirect_lock_until_usec: int = 0
var _bob_time: float = 0.0
var _base_skull_position := Vector2(0, -21)
var _bob_intensity: float = 1.0
var _feedback_tween: Tween


func _ready() -> void:
	_base_skull_position = skull_sprite.position
	_bob_time = randf() * TAU
	_bob_intensity = randf_range(0.85, 1.25)

func _physics_process(delta: float) -> void:
	if _config == null or _exited:
		return

	_bob_time += delta * 7.0 * _speed_multiplier

	var is_grounded := _is_supported()
	if not is_grounded:
		velocity.y += _gravity * _config.fall_gravity_scale * delta
	else:
		global_position.y = floor_y
		velocity.y = maxf(velocity.y, 0.0)

	velocity.x = _walk_direction * _current_walk_speed()
	global_position += velocity * delta

	if _is_supported():
		global_position.y = floor_y
		velocity.y = 0.0

	_update_presentation()

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


func set_support_bounds(left_x: float, right_x: float) -> void:
	_support_left_x = left_x
	_support_right_x = right_x


func redirect(by_player_position: Vector2) -> void:
	var now_usec := Time.get_ticks_usec()
	if now_usec < _redirect_lock_until_usec or _is_moving_toward_correct_side():
		return

	requested_redirect.emit(by_player_position)
	_walk_direction = RIGHT if global_position.x > by_player_position.x else LEFT
	_redirect_lock_until_usec = now_usec + int(_config.redirect_lock_seconds * 1000000.0)
	velocity.x = _walk_direction * _config.redirect_push_speed * _speed_multiplier
	velocity.y = minf(velocity.y, -120.0)
	redirected.emit()


func _current_walk_speed() -> float:
	var base_speed := _config.grounded_walk_speed if _is_supported() else _config.airborne_walk_speed
	return base_speed * _speed_multiplier


func _leave(side: String) -> void:
	if _exited:
		return

	_exited = true
	exited.emit(side, _color_name)
	resolved.emit()
	queue_free()


func _update_visuals() -> void:
	body_sprite.modulate = Color("#ffb0b0") if _color_name == "red" else Color("#b9ffb9")
	skull_sprite.modulate = body_sprite.modulate
	_update_presentation()


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


func play_redirect_feedback() -> void:
	if is_instance_valid(_feedback_tween):
		_feedback_tween.kill()

	body_sprite.self_modulate = Color.WHITE
	skull_sprite.self_modulate = Color.WHITE
	body_sprite.scale = Vector2(0.9, 0.9)
	skull_sprite.scale = Vector2(0.9, 0.9)
	_feedback_tween = create_tween()
	_feedback_tween.set_trans(Tween.TRANS_BACK)
	_feedback_tween.set_ease(Tween.EASE_OUT)
	_feedback_tween.parallel().tween_property(body_sprite, "scale", Vector2(1.02, 0.82), 0.08)
	_feedback_tween.parallel().tween_property(skull_sprite, "scale", Vector2(1.06, 0.84), 0.08)
	_feedback_tween.parallel().tween_property(body_sprite, "self_modulate", Color(1.0, 0.96, 0.92, 1.0), 0.08)
	_feedback_tween.parallel().tween_property(skull_sprite, "self_modulate", Color(1.0, 0.96, 0.92, 1.0), 0.08)
	_feedback_tween.tween_callback(func() -> void:
		body_sprite.scale = Vector2(0.9, 0.9)
		skull_sprite.scale = Vector2(0.9, 0.9)
		body_sprite.self_modulate = Color.WHITE
		skull_sprite.self_modulate = Color.WHITE
	)


func _is_supported() -> bool:
	return (
		global_position.y >= floor_y
		and global_position.y <= floor_y + SUPPORT_SNAP_MARGIN
		and global_position.x >= _support_left_x
		and global_position.x <= _support_right_x
	)


func _update_presentation() -> void:
	body_sprite.flip_h = _walk_direction < 0
	skull_sprite.flip_h = _walk_direction < 0
	var grounded := _is_supported()
	var bob_amount := sin(_bob_time) * (1.8 if grounded else 0.9) * _bob_intensity
	skull_sprite.position = _base_skull_position + Vector2(bob_amount, 0.0)
	shadow.scale.x = 0.92 if grounded else 0.66
	shadow.modulate.a = 0.16 if grounded else 0.08

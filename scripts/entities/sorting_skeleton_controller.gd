extends CharacterBody2D
class_name SortingSkeletonController

signal requested_redirect(by_player_position: Vector2)
signal exited(side: String, color_name: String)
signal resolved

const LEFT := -1
const RIGHT := 1

@export var floor_y: float = 978.0

@onready var body_polygon: Polygon2D = $BodyPolygon
@onready var redirect_area: Area2D = $RedirectArea

var _config: SkeletonConfig
var _color_name: String = "red"
var _walk_direction: int = RIGHT
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var _left_exit_x: float = 0.0
var _right_exit_x: float = 0.0
var _exited: bool = false
var _speed_bonus: float = 0.0


func _ready() -> void:
	redirect_area.body_entered.connect(_on_redirect_area_body_entered)


func _physics_process(delta: float) -> void:
	if _config == null or _exited:
		return

	if not is_on_floor():
		velocity.y += _gravity * _config.fall_gravity_scale * delta
	else:
		velocity.y = maxf(velocity.y, 0.0)

	velocity.x = _walk_direction * _current_walk_speed()
	move_and_slide()

	if global_position.x <= _left_exit_x:
		_leave("left")
	elif global_position.x >= _right_exit_x:
		_leave("right")


func setup(config: SkeletonConfig, color_name: String, resolved_count: int) -> void:
	_config = config
	_color_name = color_name
	_walk_direction = [LEFT, RIGHT].pick_random()
	velocity = Vector2.ZERO
	_update_visuals()
	apply_difficulty(resolved_count)


func apply_difficulty(resolved_count: int) -> void:
	_speed_bonus = resolved_count * _config.speed_gain_per_resolved


func set_exit_bounds(left_exit_x: float, right_exit_x: float) -> void:
	_left_exit_x = left_exit_x
	_right_exit_x = right_exit_x


func redirect(by_player_position: Vector2) -> void:
	requested_redirect.emit(by_player_position)
	_walk_direction = RIGHT if global_position.x > by_player_position.x else LEFT
	velocity.x = _walk_direction * _config.redirect_push_speed


func _current_walk_speed() -> float:
	return _config.base_walk_speed + _speed_bonus


func _leave(side: String) -> void:
	if _exited:
		return

	_exited = true
	exited.emit(side, _color_name)
	resolved.emit()
	queue_free()


func _on_redirect_area_body_entered(body: Node) -> void:
	if body is PlayerController:
		redirect(body.global_position)


func _update_visuals() -> void:
	body_polygon.color = Color("#d6544b") if _color_name == "red" else Color("#5ec27f")

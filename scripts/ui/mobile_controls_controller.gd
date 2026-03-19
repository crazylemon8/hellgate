extends Control
class_name MobileControlsController

signal input_changed(input_state: PlayerInputState)

const JOYSTICK_RADIUS := 92.0
const JOYSTICK_DEADZONE := 0.00
const JUMP_TRIGGER_Y := -0.35
@onready var joystick_area: Control = $JoystickArea
@onready var base_glow: Control = $JoystickArea/BaseGlow
@onready var base: Control = $JoystickArea/Base
@onready var knob: Control = $JoystickArea/Knob
@onready var sprint_button: Button = $SprintButton

var _touch_id: int = -1
var _sprint_touch_id: int = -1
var _sprint_mouse_pressed := false
var _state := PlayerInputState.new()
var _joystick_center: Vector2 = Vector2.ZERO
var _knob_tween: Tween
var _release_tween: Tween


func _ready() -> void:
	joystick_area.gui_input.connect(_on_joystick_gui_input)
	sprint_button.gui_input.connect(_on_sprint_button_gui_input)
	_reset_knob()
	_set_visual_state(false)


func _on_joystick_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and (_touch_id == -1 or _touch_id == event.index):
			if not _is_inside_joystick(event.position):
				return
			_touch_id = event.index
			_set_visual_state(true)
			_update_axis(event.position)
		elif not event.pressed and event.index == _touch_id:
			_release_joystick()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_update_axis(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not _is_inside_joystick(event.position):
				return
			_set_visual_state(true)
			_update_axis(event.position)
		else:
			_release_joystick()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_axis(event.position)


func _on_sprint_button_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_sprint_touch_id = event.index
			_set_sprint_held(true)
		elif event.index == _sprint_touch_id:
			_sprint_touch_id = -1
			_set_sprint_held(false)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_sprint_mouse_pressed = event.pressed
		_set_sprint_held(event.pressed)
	elif event is InputEventMouseMotion and _sprint_mouse_pressed:
		var is_inside := Rect2(Vector2.ZERO, sprint_button.size).has_point(event.position)
		_set_sprint_held(is_inside)


func _update_axis(local_position: Vector2) -> void:
	var offset := local_position - _joystick_center
	offset = offset.limit_length(JOYSTICK_RADIUS)
	_move_knob_to(_joystick_center + offset - (knob.size * 0.5))

	var normalized := offset / JOYSTICK_RADIUS
	var length := normalized.length()
	if length < JOYSTICK_DEADZONE:
		_state.move_x = 0.0
	else:
		var scaled_length := (length - JOYSTICK_DEADZONE) / (1.0 - JOYSTICK_DEADZONE)
		scaled_length = clampf(scaled_length, 0.0, 1.0)
		var response := normalized.normalized() * scaled_length
		_state.move_x = response.x
		if absf(_state.move_x) < 0.08:
			_state.move_x = signf(_state.move_x) * 0.08

	_state.jump_pressed = normalized.y < JUMP_TRIGGER_Y

	input_changed.emit(_state.duplicate())


func _reset_knob() -> void:
	_joystick_center = joystick_area.size * 0.5
	var base_target := _joystick_center - (base.size * 0.5)
	var glow_target := _joystick_center - (base_glow.size * 0.5)
	var knob_target := _joystick_center - (knob.size * 0.5)
	if is_instance_valid(_release_tween):
		_release_tween.kill()
	_release_tween = create_tween()
	_release_tween.set_trans(Tween.TRANS_BACK)
	_release_tween.set_ease(Tween.EASE_OUT)
	_release_tween.parallel().tween_property(base, "position", base_target, 0.14)
	_release_tween.parallel().tween_property(base_glow, "position", glow_target, 0.14)
	_release_tween.parallel().tween_property(knob, "position", knob_target, 0.14)


func reset_input() -> void:
	_touch_id = -1
	_sprint_touch_id = -1
	_sprint_mouse_pressed = false
	_state = PlayerInputState.new()
	_reset_knob()
	input_changed.emit(_state.duplicate())


func _release_joystick() -> void:
	_touch_id = -1
	_state.move_x = 0.0
	_state.jump_pressed = false
	_set_visual_state(false)
	_reset_knob()
	input_changed.emit(_state.duplicate())


func _move_knob_to(target_position: Vector2) -> void:
	if is_instance_valid(_knob_tween):
		_knob_tween.kill()
	_knob_tween = create_tween()
	_knob_tween.set_trans(Tween.TRANS_SINE)
	_knob_tween.set_ease(Tween.EASE_OUT)
	_knob_tween.tween_property(knob, "position", target_position, 0.045)


func _set_visual_state(is_active: bool) -> void:
	base_glow.modulate.a = 0.44 if is_active else 0.22
	base.scale = Vector2.ONE * (1.05 if is_active else 1.0)
	knob.scale = Vector2.ONE * (1.08 if is_active else 1.0)


func _set_sprint_held(is_held: bool) -> void:
	if _state.sprint_held == is_held:
		return
	_state.sprint_held = is_held
	input_changed.emit(_state.duplicate())


func _is_inside_joystick(local_position: Vector2) -> bool:
	return local_position.distance_to(_joystick_center) <= JOYSTICK_RADIUS * 1.2

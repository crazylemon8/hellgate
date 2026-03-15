extends Control
class_name MobileControlsController

signal input_changed(input_state: PlayerInputState)

const JOYSTICK_RADIUS := 92.0
const JOYSTICK_DEADZONE := 0.18
const JUMP_TRIGGER_Y := -0.62

@onready var joystick_area: Control = $JoystickArea
@onready var base: ColorRect = $JoystickArea/Base
@onready var knob: ColorRect = $JoystickArea/Knob
@onready var sprint_button: Button = $SprintButton

var _touch_id: int = -1
var _state := PlayerInputState.new()
var _joystick_center: Vector2 = Vector2.ZERO
var _jump_armed: bool = true


func _ready() -> void:
	joystick_area.gui_input.connect(_on_joystick_gui_input)
	sprint_button.button_down.connect(_on_sprint_button_down)
	sprint_button.button_up.connect(_on_sprint_button_up)
	_reset_knob()


func _on_joystick_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and (_touch_id == -1 or _touch_id == event.index):
			_touch_id = event.index
			_set_joystick_center(event.position)
			_update_axis(event.position)
		elif not event.pressed and event.index == _touch_id:
			_release_joystick()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_update_axis(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_set_joystick_center(event.position)
			_update_axis(event.position)
		else:
			_release_joystick()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_axis(event.position)


func _on_sprint_button_down() -> void:
	_state.sprint_held = true
	input_changed.emit(_state.duplicate())


func _on_sprint_button_up() -> void:
	_state.sprint_held = false
	input_changed.emit(_state.duplicate())


func _update_axis(local_position: Vector2) -> void:
	var offset := local_position - _joystick_center
	offset = offset.limit_length(JOYSTICK_RADIUS)
	knob.position = _joystick_center + offset - (knob.size * 0.5)

	var normalized := offset / JOYSTICK_RADIUS
	var length := normalized.length()
	if length < JOYSTICK_DEADZONE:
		_state.move_x = 0.0
	else:
		var scaled_length := (length - JOYSTICK_DEADZONE) / (1.0 - JOYSTICK_DEADZONE)
		scaled_length = clampf(scaled_length, 0.0, 1.0)
		var response := normalized.normalized() * scaled_length
		_state.move_x = response.x

	var jump_vector_y := normalized.y
	if jump_vector_y <= JUMP_TRIGGER_Y and _jump_armed:
		_state.jump_pressed = true
		_jump_armed = false
	elif jump_vector_y > JUMP_TRIGGER_Y * 0.45:
		_jump_armed = true

	input_changed.emit(_state.duplicate())
	_state.jump_pressed = false


func _reset_knob() -> void:
	_joystick_center = joystick_area.size * 0.5
	base.position = _joystick_center - (base.size * 0.5)
	knob.position = _joystick_center - (knob.size * 0.5)


func reset_input() -> void:
	_touch_id = -1
	_state = PlayerInputState.new()
	_jump_armed = true
	_reset_knob()
	input_changed.emit(_state.duplicate())


func _set_joystick_center(local_position: Vector2) -> void:
	var half_base := base.size * 0.5
	_joystick_center = Vector2(
		clampf(local_position.x, half_base.x, joystick_area.size.x - half_base.x),
		clampf(local_position.y, half_base.y, joystick_area.size.y - half_base.y)
	)
	base.position = _joystick_center - half_base
	knob.position = _joystick_center - (knob.size * 0.5)


func _release_joystick() -> void:
	_touch_id = -1
	_state.move_x = 0.0
	_state.jump_pressed = false
	_jump_armed = true
	_reset_knob()
	input_changed.emit(_state.duplicate())

extends Control
class_name MobileControlsController

signal input_changed(input_state: PlayerInputState)

const JOYSTICK_RADIUS := 92.0

@onready var joystick_area: Control = $JoystickArea
@onready var knob: ColorRect = $JoystickArea/Knob
@onready var sprint_button: Button = $SprintButton

var _touch_id: int = -1
var _state := PlayerInputState.new()


func _ready() -> void:
	joystick_area.gui_input.connect(_on_joystick_gui_input)
	sprint_button.button_down.connect(_on_sprint_button_down)
	sprint_button.button_up.connect(_on_sprint_button_up)
	_reset_knob()


func _on_joystick_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and (_touch_id == -1 or _touch_id == event.index):
			_touch_id = event.index
			_update_axis(event.position)
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			_state.move_x = 0.0
			_reset_knob()
			input_changed.emit(_state.duplicate())
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_update_axis(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_update_axis(event.position)
		else:
			_touch_id = -1
			_state.move_x = 0.0
			_reset_knob()
			input_changed.emit(_state.duplicate())
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_axis(event.position)


func _on_sprint_button_down() -> void:
	_state.sprint_held = true
	input_changed.emit(_state.duplicate())


func _on_sprint_button_up() -> void:
	_state.sprint_held = false
	input_changed.emit(_state.duplicate())


func _update_axis(local_position: Vector2) -> void:
	var center := joystick_area.size * 0.5
	var offset := local_position - center
	offset = offset.limit_length(JOYSTICK_RADIUS)
	knob.position = center + offset - (knob.size * 0.5)
	_state.move_x = clampf(offset.x / JOYSTICK_RADIUS, -1.0, 1.0)
	input_changed.emit(_state.duplicate())


func _reset_knob() -> void:
	var center := joystick_area.size * 0.5
	knob.position = center - (knob.size * 0.5)


func reset_input() -> void:
	_touch_id = -1
	_state = PlayerInputState.new()
	_reset_knob()
	input_changed.emit(_state.duplicate())

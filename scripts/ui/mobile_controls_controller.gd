extends Control
class_name MobileControlsController

signal input_changed(input_state: PlayerInputState)
signal layout_edit_mode_changed(is_editing: bool)

const JOYSTICK_RADIUS := 92.0
const JOYSTICK_DEADZONE := 0.00
const JUMP_TRIGGER_Y := -0.35
@onready var joystick_area: Control = $JoystickArea
@onready var base_glow: Control = $JoystickArea/BaseGlow
@onready var base: Control = $JoystickArea/Base
@onready var knob: Control = $JoystickArea/Knob
@onready var sprint_button: Button = $SprintButton
@onready var sprint_meter: CircularMeter = $SprintMeter

var _touch_id: int = -1
var _sprint_touch_id: int = -1
var _sprint_mouse_pressed := false
var _state := PlayerInputState.new()
var _joystick_center: Vector2 = Vector2.ZERO
var _knob_tween: Tween
var _release_tween: Tween
var _layout_edit_mode := false
var _layout_drag_target: Control
var _layout_drag_touch_id := -1
var _layout_drag_offset: Vector2 = Vector2.ZERO
var _sprint_meter_delta_from_button: Vector2 = Vector2.ZERO
var _defaults_applied := false
var _default_joystick_norm := Vector2.ZERO
var _default_sprint_norm := Vector2.ZERO


func _ready() -> void:
	joystick_area.gui_input.connect(_on_joystick_gui_input)
	sprint_button.gui_input.connect(_on_sprint_button_gui_input)
	_sprint_meter_delta_from_button = sprint_meter.position - sprint_button.position
	_cache_default_layout_if_needed()
	set_sprint_ratio(1.0)
	_reset_knob()
	_set_visual_state(false)


func _on_joystick_gui_input(event: InputEvent) -> void:
	if _layout_edit_mode:
		_handle_layout_drag_event(event, joystick_area)
		return

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
	if _layout_edit_mode:
		_handle_layout_drag_event(event, sprint_button)
		return

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
	if _layout_edit_mode:
		return
	if _state.sprint_held == is_held:
		return
	_state.sprint_held = is_held
	input_changed.emit(_state.duplicate())


func _is_inside_joystick(local_position: Vector2) -> bool:
	return local_position.distance_to(_joystick_center) <= JOYSTICK_RADIUS * 1.2


func set_sprint_ratio(current_ratio: float) -> void:
	sprint_meter.set_ratio(current_ratio)


func set_layout_edit_mode(enabled: bool) -> void:
	if _layout_edit_mode == enabled:
		return

	_layout_edit_mode = enabled
	_layout_drag_target = null
	_layout_drag_touch_id = -1
	_touch_id = -1
	_sprint_touch_id = -1
	_sprint_mouse_pressed = false
	_state = PlayerInputState.new()
	input_changed.emit(_state.duplicate())
	_reset_knob()
	_set_visual_state(false)
	layout_edit_mode_changed.emit(enabled)


func is_layout_edit_mode() -> bool:
	return _layout_edit_mode


func get_layout_state() -> Dictionary:
	return {
		"joystick_norm": _position_to_norm(joystick_area.position, joystick_area.size),
		"sprint_norm": _position_to_norm(sprint_button.position, sprint_button.size),
	}


func apply_layout_state(layout: Dictionary) -> void:
	var joystick_norm: Vector2 = layout.get("joystick_norm", Vector2(-1.0, -1.0))
	var sprint_norm: Vector2 = layout.get("sprint_norm", Vector2(-1.0, -1.0))
	if joystick_norm.x >= 0.0 and joystick_norm.y >= 0.0:
		_apply_norm_to_control(joystick_area, joystick_norm)
	if sprint_norm.x >= 0.0 and sprint_norm.y >= 0.0:
		_apply_norm_to_control(sprint_button, sprint_norm)
		_sync_sprint_meter_to_button()
	_reset_knob()


func reset_layout_to_default() -> Dictionary:
	_cache_default_layout_if_needed()
	_apply_norm_to_control(joystick_area, _default_joystick_norm)
	_apply_norm_to_control(sprint_button, _default_sprint_norm)
	_sync_sprint_meter_to_button()
	_reset_knob()
	return get_layout_state()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_sprint_meter_to_button()
		_reset_knob()


func _handle_layout_drag_event(event: InputEvent, target: Control) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_layout_drag_touch_id = event.index
			_layout_drag_target = target
			_layout_drag_offset = event.position - target.global_position
		elif event.index == _layout_drag_touch_id:
			_layout_drag_touch_id = -1
			_layout_drag_target = null
	elif event is InputEventScreenDrag and event.index == _layout_drag_touch_id and _layout_drag_target == target:
		_move_layout_target(target, event.position - _layout_drag_offset)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_layout_drag_target = target
			var mouse_position := get_viewport().get_mouse_position()
			_layout_drag_offset = mouse_position - target.global_position
		else:
			_layout_drag_target = null
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _layout_drag_target == target:
		var mouse_position := get_viewport().get_mouse_position()
		_move_layout_target(target, mouse_position - _layout_drag_offset)


func _move_layout_target(target: Control, desired_global_top_left: Vector2) -> void:
	var parent_control := target.get_parent() as Control
	if parent_control == null:
		return

	var parent_global := parent_control.global_position
	var local_top_left := desired_global_top_left - parent_global
	local_top_left.x = clampf(local_top_left.x, 0.0, maxf(0.0, parent_control.size.x - target.size.x))
	local_top_left.y = clampf(local_top_left.y, 0.0, maxf(0.0, parent_control.size.y - target.size.y))
	_set_control_top_left(target, local_top_left)
	if target == sprint_button:
		_sync_sprint_meter_to_button()

	_reset_knob()


func _set_control_top_left(control: Control, local_top_left: Vector2) -> void:
	var parent_control := control.get_parent() as Control
	if parent_control == null:
		return

	var parent_size := parent_control.size
	var left := local_top_left.x
	var top := local_top_left.y
	var right := left + control.size.x
	var bottom := top + control.size.y
	control.offset_left = left - (parent_size.x * control.anchor_left)
	control.offset_top = top - (parent_size.y * control.anchor_top)
	control.offset_right = right - (parent_size.x * control.anchor_right)
	control.offset_bottom = bottom - (parent_size.y * control.anchor_bottom)


func _position_to_norm(local_top_left: Vector2, control_size: Vector2) -> Vector2:
	var span := size - control_size
	if span.x <= 0.0 or span.y <= 0.0:
		return Vector2.ZERO
	return Vector2(clampf(local_top_left.x / span.x, 0.0, 1.0), clampf(local_top_left.y / span.y, 0.0, 1.0))


func _apply_norm_to_control(control: Control, norm: Vector2) -> void:
	var span := size - control.size
	var top_left := Vector2(span.x * clampf(norm.x, 0.0, 1.0), span.y * clampf(norm.y, 0.0, 1.0))
	_set_control_top_left(control, top_left)


func _sync_sprint_meter_to_button() -> void:
	_set_control_top_left(sprint_meter, sprint_button.position + _sprint_meter_delta_from_button)


func _cache_default_layout_if_needed() -> void:
	if _defaults_applied:
		return
	_default_joystick_norm = _position_to_norm(joystick_area.position, joystick_area.size)
	_default_sprint_norm = _position_to_norm(sprint_button.position, sprint_button.size)
	_defaults_applied = true

extends RefCounted
class_name PlayerInputState

var move_x: float = 0.0
var jump_pressed: bool = false
var sprint_held: bool = false
var pause_pressed: bool = false


func duplicate() -> PlayerInputState:
	var state := PlayerInputState.new()
	state.move_x = move_x
	state.jump_pressed = jump_pressed
	state.sprint_held = sprint_held
	state.pause_pressed = pause_pressed
	return state

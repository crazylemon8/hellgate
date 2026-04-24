extends RefCounted
class_name SaveState

const SAVE_PATH := "user://save_state.cfg"
const SECTION_PROGRESS := "progress"
const KEY_TUTORIAL_COMPLETED := "tutorial_completed"
const SECTION_SETTINGS := "settings"
const KEY_MUSIC_ENABLED := "music_enabled"
const KEY_SFX_ENABLED := "sfx_enabled"
const KEY_JOYSTICK_LAYOUT_X := "joystick_layout_x"
const KEY_JOYSTICK_LAYOUT_Y := "joystick_layout_y"
const KEY_SPRINT_LAYOUT_X := "sprint_layout_x"
const KEY_SPRINT_LAYOUT_Y := "sprint_layout_y"
const SECTION_STATS := "stats"
const KEY_HIGH_SCORE := "high_score"


static func is_tutorial_completed() -> bool:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		return false

	return bool(config.get_value(SECTION_PROGRESS, KEY_TUTORIAL_COMPLETED, false))


static func set_tutorial_completed(value: bool) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value(SECTION_PROGRESS, KEY_TUTORIAL_COMPLETED, value)
	config.save(SAVE_PATH)


static func is_music_enabled() -> bool:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		return true

	return bool(config.get_value(SECTION_SETTINGS, KEY_MUSIC_ENABLED, true))


static func set_music_enabled(value: bool) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value(SECTION_SETTINGS, KEY_MUSIC_ENABLED, value)
	config.save(SAVE_PATH)


static func is_sfx_enabled() -> bool:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		return true

	return bool(config.get_value(SECTION_SETTINGS, KEY_SFX_ENABLED, true))


static func set_sfx_enabled(value: bool) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value(SECTION_SETTINGS, KEY_SFX_ENABLED, value)
	config.save(SAVE_PATH)


static func get_mobile_controls_layout() -> Dictionary:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		return {}

	var has_joystick := config.has_section_key(SECTION_SETTINGS, KEY_JOYSTICK_LAYOUT_X) and config.has_section_key(SECTION_SETTINGS, KEY_JOYSTICK_LAYOUT_Y)
	var has_sprint := config.has_section_key(SECTION_SETTINGS, KEY_SPRINT_LAYOUT_X) and config.has_section_key(SECTION_SETTINGS, KEY_SPRINT_LAYOUT_Y)
	if not has_joystick and not has_sprint:
		return {}

	var layout := {}
	if has_joystick:
		layout.joystick_norm = Vector2(
			clampf(float(config.get_value(SECTION_SETTINGS, KEY_JOYSTICK_LAYOUT_X, 0.0)), 0.0, 1.0),
			clampf(float(config.get_value(SECTION_SETTINGS, KEY_JOYSTICK_LAYOUT_Y, 0.0)), 0.0, 1.0)
		)
	if has_sprint:
		layout.sprint_norm = Vector2(
			clampf(float(config.get_value(SECTION_SETTINGS, KEY_SPRINT_LAYOUT_X, 0.0)), 0.0, 1.0),
			clampf(float(config.get_value(SECTION_SETTINGS, KEY_SPRINT_LAYOUT_Y, 0.0)), 0.0, 1.0)
		)
	return layout


static func set_mobile_controls_layout(layout: Dictionary) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)

	var joystick_norm: Vector2 = layout.get("joystick_norm", Vector2.ZERO)
	var sprint_norm: Vector2 = layout.get("sprint_norm", Vector2.ZERO)
	config.set_value(SECTION_SETTINGS, KEY_JOYSTICK_LAYOUT_X, clampf(joystick_norm.x, 0.0, 1.0))
	config.set_value(SECTION_SETTINGS, KEY_JOYSTICK_LAYOUT_Y, clampf(joystick_norm.y, 0.0, 1.0))
	config.set_value(SECTION_SETTINGS, KEY_SPRINT_LAYOUT_X, clampf(sprint_norm.x, 0.0, 1.0))
	config.set_value(SECTION_SETTINGS, KEY_SPRINT_LAYOUT_Y, clampf(sprint_norm.y, 0.0, 1.0))
	config.save(SAVE_PATH)


static func clear_mobile_controls_layout() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.erase_section_key(SECTION_SETTINGS, KEY_JOYSTICK_LAYOUT_X)
	config.erase_section_key(SECTION_SETTINGS, KEY_JOYSTICK_LAYOUT_Y)
	config.erase_section_key(SECTION_SETTINGS, KEY_SPRINT_LAYOUT_X)
	config.erase_section_key(SECTION_SETTINGS, KEY_SPRINT_LAYOUT_Y)
	config.save(SAVE_PATH)


static func get_high_score() -> int:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		return 0

	return int(config.get_value(SECTION_STATS, KEY_HIGH_SCORE, 0))


static func set_high_score(value: int) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value(SECTION_STATS, KEY_HIGH_SCORE, max(value, 0))
	config.save(SAVE_PATH)


static func update_high_score(candidate_score: int) -> bool:
	var current_high_score := get_high_score()
	if candidate_score <= current_high_score:
		return false

	set_high_score(candidate_score)
	return true

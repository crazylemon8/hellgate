extends RefCounted
class_name SaveState

const SAVE_PATH := "user://save_state.cfg"
const SECTION_PROGRESS := "progress"
const KEY_TUTORIAL_COMPLETED := "tutorial_completed"
const SECTION_SETTINGS := "settings"
const KEY_MUSIC_ENABLED := "music_enabled"
const KEY_SFX_ENABLED := "sfx_enabled"


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

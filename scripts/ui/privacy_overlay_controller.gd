extends Control
class_name PrivacyOverlayController

@export_file("*.md", "*.txt") var policy_path := "res://PRIVACY.md"

@onready var backdrop: ColorRect = $Backdrop
@onready var body_label: RichTextLabel = $CenterContainer/Panel/VBoxContainer/BodyMargin/Body
@onready var footer_close_button: Button = $CenterContainer/Panel/VBoxContainer/CloseButton


func _ready() -> void:
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	footer_close_button.pressed.connect(hide_overlay)
	body_label.bbcode_enabled = true
	hide_overlay()
	_load_policy_text()


func show_overlay() -> void:
	visible = true


func hide_overlay() -> void:
	visible = false


func _load_policy_text() -> void:
	if not FileAccess.file_exists(policy_path):
		body_label.text = "[center]Privacy policy unavailable.[/center]"
		return

	var file := FileAccess.open(policy_path, FileAccess.READ)
	if file == null:
		body_label.text = "[center]Privacy policy unavailable.[/center]"
		return

	body_label.text = _markdown_to_bbcode(file.get_as_text())


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_overlay()
	elif event is InputEventScreenTouch and event.pressed:
		hide_overlay()


func _markdown_to_bbcode(markdown: String) -> String:
	var lines := markdown.split("\n")
	var output: PackedStringArray = []

	for raw_line in lines:
		var line := raw_line.strip_edges()

		if line.is_empty():
			output.append("")
			continue

		if line.begins_with("# "):
			output.append("[center][font_size=26][b]%s[/b][/font_size][/center]" % _escape_bbcode(line.trim_prefix("# ")))
			continue

		if line.begins_with("## "):
			output.append("")
			output.append("[font_size=20][b][color=#ffba45]%s[/color][/b][/font_size]" % _escape_bbcode(line.trim_prefix("## ")))
			continue

		if line.begins_with("### "):
			output.append("")
			output.append("[font_size=17][b]%s[/b][/font_size]" % _escape_bbcode(line.trim_prefix("### ")))
			continue

		if line.begins_with("- "):
			output.append("[font_size=16][indent]• %s[/indent][/font_size]" % _escape_bbcode(line.trim_prefix("- ")))
			continue

		output.append("[font_size=16]%s[/font_size]" % _escape_bbcode(line))

	return "\n".join(output)


func _escape_bbcode(value: String) -> String:
	return value.replace("[", "[lb]").replace("]", "[rb]")

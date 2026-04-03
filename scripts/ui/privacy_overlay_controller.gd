extends Control
class_name PrivacyOverlayController

@export_file("*.md", "*.txt") var policy_path := "res://PRIVACY.md"

@onready var backdrop: ColorRect = $Backdrop
@onready var body_label: RichTextLabel = $CenterContainer/Panel/VBoxContainer/BodyMargin/Body
@onready var header_close_button: Button = $CenterContainer/Panel/VBoxContainer/Header/HeaderCloseButton
@onready var footer_close_button: Button = $CenterContainer/Panel/VBoxContainer/CloseButton


func _ready() -> void:
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	header_close_button.pressed.connect(hide_overlay)
	footer_close_button.pressed.connect(hide_overlay)
	hide_overlay()
	_load_policy_text()


func show_overlay() -> void:
	visible = true


func hide_overlay() -> void:
	visible = false


func _load_policy_text() -> void:
	if not FileAccess.file_exists(policy_path):
		body_label.text = "Privacy policy unavailable."
		return

	var file := FileAccess.open(policy_path, FileAccess.READ)
	if file == null:
		body_label.text = "Privacy policy unavailable."
		return

	body_label.text = file.get_as_text()


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_overlay()
	elif event is InputEventScreenTouch and event.pressed:
		hide_overlay()

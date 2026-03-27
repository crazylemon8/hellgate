extends Control
class_name TutorialOverlayController

@onready var title_label: Label = $MarginContainer/Panel/VBoxContainer/Title
@onready var body_label: Label = $MarginContainer/Panel/VBoxContainer/Body


func show_message(title: String, body: String) -> void:
	title_label.text = title
	body_label.text = body
	visible = true


func hide_overlay() -> void:
	visible = false

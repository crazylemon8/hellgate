extends Node

@export var next_scene: PackedScene


func _ready() -> void:
	if next_scene == null:
		push_error("Bootstrap is missing a next scene.")
		return

	get_tree().change_scene_to_packed(next_scene)


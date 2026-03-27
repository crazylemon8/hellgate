extends Control

@export var next_scene: PackedScene
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	if next_scene == null:
		push_error("Bootstrap is missing a next scene.")
		return

	if animation_player == null:
		get_tree().change_scene_to_packed(next_scene)
		return

	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.play("intro")


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name != "intro":
		return

	get_tree().change_scene_to_packed(next_scene)

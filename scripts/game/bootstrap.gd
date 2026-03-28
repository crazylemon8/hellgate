extends Control

@export var next_scene: PackedScene
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var stage: Control = $Stage

const DESIGN_STAGE_SIZE := Vector2(1280.0, 720.0)


func _ready() -> void:
	if next_scene == null:
		push_error("Bootstrap is missing a next scene.")
		return

	if animation_player == null:
		get_tree().change_scene_to_packed(next_scene)
		return

	resized.connect(_layout_stage)
	_layout_stage()
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.play("intro")


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name != "intro":
		return

	get_tree().change_scene_to_packed(next_scene)


func _layout_stage() -> void:
	if stage == null:
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var scale_factor := minf(viewport_size.x / DESIGN_STAGE_SIZE.x, viewport_size.y / DESIGN_STAGE_SIZE.y)
	stage.scale = Vector2.ONE * scale_factor
	stage.size = DESIGN_STAGE_SIZE
	stage.position = (viewport_size - (DESIGN_STAGE_SIZE * scale_factor)) * 0.5

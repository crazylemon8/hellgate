extends Control
class_name HudController

signal pause_requested

@onready var score_value: Label = $MarginContainer/Row/ScorePanel/ScoreMargin/ScoreContent/Value
@onready var skulls: Array[TextureRect] = [
	$MarginContainer/Row/SkullsPanel/SkullsMargin/SkullsRow/Skull1,
	$MarginContainer/Row/SkullsPanel/SkullsMargin/SkullsRow/Skull2,
	$MarginContainer/Row/SkullsPanel/SkullsMargin/SkullsRow/Skull3,
	$MarginContainer/Row/SkullsPanel/SkullsMargin/SkullsRow/Skull4,
	$MarginContainer/Row/SkullsPanel/SkullsMargin/SkullsRow/Skull5,
]
@onready var skull_shadows: Array[TextureRect] = [
	$MarginContainer/Row/SkullsPanel/SkullsMargin/SkullsRow/Skull1/Shadow,
	$MarginContainer/Row/SkullsPanel/SkullsMargin/SkullsRow/Skull2/Shadow,
	$MarginContainer/Row/SkullsPanel/SkullsMargin/SkullsRow/Skull3/Shadow,
	$MarginContainer/Row/SkullsPanel/SkullsMargin/SkullsRow/Skull4/Shadow,
	$MarginContainer/Row/SkullsPanel/SkullsMargin/SkullsRow/Skull5/Shadow,
]
@onready var pause_button: Button = $MarginContainer/Row/PauseButton

var _last_mistakes_remaining: int = -1


func _ready() -> void:
	pause_button.pressed.connect(func() -> void:
		pause_requested.emit()
	)


func set_score(total_score: int, mistakes_remaining: int) -> void:
	score_value.text = str(total_score)
	if _last_mistakes_remaining == -1:
		_last_mistakes_remaining = mistakes_remaining

	if mistakes_remaining < _last_mistakes_remaining:
		for lost_index in range(mistakes_remaining, _last_mistakes_remaining):
			_play_skull_loss_poof(lost_index)

	for index in skulls.size():
		skulls[index].modulate.a = 1.0 if index < mistakes_remaining else 0.2
		skull_shadows[index].modulate.a = 0.28 if index < mistakes_remaining else 0.08

	_last_mistakes_remaining = mistakes_remaining


func set_speed_ratio(_current_ratio: float) -> void:
	pass


func set_paused(is_paused: bool) -> void:
	pause_button.text = ">" if is_paused else "II"


func _play_skull_loss_poof(index: int) -> void:
	if index < 0 or index >= skulls.size():
		return

	var skull := skulls[index]
	var shadow := skull_shadows[index]
	_spawn_skull_dust(skull)
	skull.scale = Vector2.ONE
	shadow.scale = Vector2.ONE

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(skull, "scale", Vector2(1.26, 1.26), 0.12)
	tween.parallel().tween_property(skull, "modulate:a", 0.05, 0.12)
	tween.parallel().tween_property(shadow, "scale", Vector2(1.18, 1.18), 0.12)
	tween.parallel().tween_property(shadow, "modulate:a", 0.02, 0.12)
	tween.tween_callback(func() -> void:
		skull.scale = Vector2.ONE
		shadow.scale = Vector2.ONE
		skull.modulate.a = 0.2
		shadow.modulate.a = 0.08
	)


func _spawn_skull_dust(skull: TextureRect) -> void:
	var burst_center := skull.get_global_rect().get_center() - global_position
	var colors := [
		Color(1.0, 1.0, 1.0, 0.95),
		Color(0.96, 0.94, 0.9, 0.9),
		Color(0.86, 0.86, 0.86, 0.65),
	]

	for particle_index in range(6):
		var particle := ColorRect.new()
		add_child(particle)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.color = colors[particle_index % colors.size()]
		particle.custom_minimum_size = Vector2(6, 6)
		particle.size = Vector2(6, 6)
		particle.pivot_offset = particle.size * 0.5
		particle.position = burst_center - (particle.size * 0.5)

		var angle := randf_range(0.0, TAU)
		var distance := randf_range(18.0, 36.0)
		var rise := randf_range(-10.0, 8.0)
		var target_position := particle.position + Vector2(cos(angle), sin(angle)) * distance + Vector2(0.0, rise)
		var target_scale := Vector2.ONE * randf_range(0.45, 0.75)

		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(particle, "position", target_position, 0.34)
		tween.parallel().tween_property(particle, "scale", target_scale, 0.34)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.34)
		tween.parallel().tween_property(particle, "rotation", randf_range(-0.9, 0.9), 0.34)
		tween.tween_callback(particle.queue_free)

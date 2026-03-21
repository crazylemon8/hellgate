extends Control
class_name HudController

signal pause_requested

@onready var score_value: Label = $ScoreCenter/ScorePanel/ScoreMargin/ScoreContent/Value
@onready var skulls: Array[TextureRect] = [
	$MarginContainer/Row/SkullsPanel/SkullsMargin/SkullsRow/Skull1,
	$MarginContainer/Row/SkullsPanel/SkullsMargin/SkullsRow/Skull2,
	$MarginContainer/Row/SkullsPanel/SkullsMargin/SkullsRow/Skull3,
	$MarginContainer/Row/SkullsPanel/SkullsMargin/SkullsRow/Skull4,
	$MarginContainer/Row/SkullsPanel/SkullsMargin/SkullsRow/Skull5,
]
@onready var speed_meter: ProgressBar = $MarginContainer/Row/SpeedPanel/SpeedMargin/VBoxContainer/SpeedMeter
@onready var pause_button: Button = $MarginContainer/Row/PauseButton


func _ready() -> void:
	pause_button.pressed.connect(func() -> void:
		pause_requested.emit()
	)


func set_score(total_score: int, mistakes_remaining: int) -> void:
	score_value.text = str(total_score)
	for index in skulls.size():
		skulls[index].visible = index < mistakes_remaining


func set_speed_ratio(current_ratio: float) -> void:
	speed_meter.value = current_ratio * 100.0


func set_paused(is_paused: bool) -> void:
	pause_button.text = ">" if is_paused else "II"

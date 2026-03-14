extends Control
class_name HudController

signal pause_requested

@onready var red_value: Label = $MarginContainer/VBoxContainer/ScoreRow/RedPanel/Value
@onready var mistakes_value: Label = $MarginContainer/VBoxContainer/ScoreRow/MistakesPanel/Value
@onready var green_value: Label = $MarginContainer/VBoxContainer/ScoreRow/GreenPanel/Value
@onready var speed_meter: ProgressBar = $MarginContainer/VBoxContainer/UtilityRow/SpeedPanel/SpeedMargin/VBoxContainer/SpeedMeter
@onready var pause_button: Button = $MarginContainer/VBoxContainer/UtilityRow/PauseButton


func _ready() -> void:
	pause_button.pressed.connect(func() -> void:
		pause_requested.emit()
	)


func set_score(red_sorted: int, green_sorted: int, mistakes_remaining: int) -> void:
	red_value.text = str(red_sorted)
	green_value.text = str(green_sorted)
	mistakes_value.text = str(mistakes_remaining)


func set_speed_ratio(current_ratio: float) -> void:
	speed_meter.value = current_ratio * 100.0


func set_paused(is_paused: bool) -> void:
	pause_button.text = "Resume" if is_paused else "Pause"

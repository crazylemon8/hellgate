extends Control
class_name CircularMeter

@export var track_color: Color = Color(0.278431, 0.113725, 0.082353, 0.45)
@export var fill_color: Color = Color(1.0, 0.560784, 0.25098, 0.95)
@export var line_width: float = 5.0
@export var start_angle_deg: float = -90.0
@export var max_angle_deg: float = 360.0

var _ratio: float = 1.0


func set_ratio(value: float) -> void:
	_ratio = clampf(value, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := maxf(8.0, minf(size.x, size.y) * 0.5 - (line_width * 0.8))
	var start_angle := deg_to_rad(start_angle_deg)
	var end_angle := start_angle + deg_to_rad(max_angle_deg)
	draw_arc(center, radius, start_angle, end_angle, 64, track_color, line_width, true)
	if _ratio <= 0.0:
		return
	var progress_end := start_angle + deg_to_rad(max_angle_deg * _ratio)
	draw_arc(center, radius, start_angle, progress_end, 64, fill_color, line_width, true)

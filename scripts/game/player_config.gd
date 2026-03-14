extends Resource
class_name PlayerConfig

@export var move_speed: float = 280.0
@export var sprint_multiplier: float = 1.45
@export var jump_velocity: float = -460.0
@export var gravity_scale: float = 1.0
@export var sprint_drain_per_second: float = 0.22
@export var sprint_recovery_per_second: float = 0.16
@export_range(0.0, 1.0, 0.01) var initial_sprint_ratio: float = 1.0


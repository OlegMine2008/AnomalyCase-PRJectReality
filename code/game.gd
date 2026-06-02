extends Node3D

const CLOCK_ANIMATION := &"default"
const START_BASE_TIME := 360.0
const SECONDS_PER_HOUR := 60.0

@onready var clocks: AnimatedSprite2D = $clocks

var base_time := START_BASE_TIME
var is_finished := false


func _ready() -> void:
	_update_clock_frame()


func _process(delta: float) -> void:
	if is_finished:
		return

	base_time = max(base_time - delta, 0.0)
	_update_clock_frame()

	if base_time <= 0.0:
		is_finished = true
		get_tree().quit()


func _update_clock_frame() -> void:
	var frame_count := clocks.sprite_frames.get_frame_count(CLOCK_ANIMATION)
	if frame_count <= 0:
		return

	var elapsed_hours := int((START_BASE_TIME - base_time) / SECONDS_PER_HOUR)
	clocks.frame = clampi(elapsed_hours, 0, frame_count - 1)

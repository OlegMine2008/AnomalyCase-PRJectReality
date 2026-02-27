extends Node2D

@export var cams: Cameras
@export var offic: Office
@onready var text: Sprite2D = $CamMenu


# Called when the node enters the scene tree for the first time.
func _ready():
	if cams == null:
		push_error("Cam_Sys: export 'cams' is not assigned.")
		return
	if offic == null:
		push_error("Cam_Sys: export 'offic' is not assigned.")
		return
	text.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float):
	if cams == null or offic == null:
		return
	var show_cam_ui := offic.cams_on and offic.cam_transition_done
	text.visible = show_cam_ui

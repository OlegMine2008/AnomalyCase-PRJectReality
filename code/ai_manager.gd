extends Node

@export_range(0, 20) var oleg_level: int
@export_range(0, 20) var felix_level: int


func _ready() -> void:
	randomize() # Sets new RNG seed
	_initialize_char_levels()


func _initialize_char_levels() -> void:
	var felix: Node = get_node_or_null("FelixTheWolf")
	if felix == null:
		push_error("FelixTheWolf node was not found under Enemies.")
		return

	if felix is AI:
		var felix_ai: AI = felix as AI
		felix_ai.ai_level = felix_level
		felix_ai.character = 1 # Felix index in Cameras.gd state map

		if felix_ai.camera == null:
			var cameras_node: Node = get_node_or_null("../Cam_Sys/Cam_Buttons")
			if cameras_node is Cameras:
				felix_ai.camera = cameras_node as Cameras
			else:
				push_warning("Cameras node not found at ../Cam_Sys/Cam_Buttons, Felix visual state sync is disabled.")
	else:
		push_error("FelixTheWolf must inherit AI. Current script: %s" % [felix.get_script()])

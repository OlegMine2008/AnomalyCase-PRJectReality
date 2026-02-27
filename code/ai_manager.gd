extends Node

@export_range(0, 20) var oleg_level: int
@export_range(0, 20) var felix_level: int

func _ready() -> void:
	randomize() # Sets new RNG seed
	_initialize_char_levels()


func _initialize_char_levels() -> void:
	var felix: Node = $FelixTheWolf
	if felix is AI:
		(felix as AI).ai_level = felix_level
	else:
		push_error("FelixTheWolf must inherit AI. Current script: %s" % [felix.get_script()])

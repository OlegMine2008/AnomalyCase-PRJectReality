extends Node

#@export_range(0, 20, 1) var oleg_level: int = 0
#@export_range(0, 20, 1) var felix_level: int = 0
var oleg_level = 4
var felix_level = 3

# Инициализирует генератор случайности и стартовые уровни ИИ.
func _ready() -> void:
	randomize()
	_initialize_char_levels()

# Прокидывает уровни сложности и ссылки на камеры в ноды противников.
func _initialize_char_levels() -> void:
	var cams: Cameras = get_node_or_null("../Cam_Sys/Cam_Buttons") as Cameras
	var oleg: Node = get_node_or_null("OlegTheCat")

	if oleg != null:
		oleg.set("bdifficulty", oleg_level)
		if cams != null and oleg.get("cams") == null:
			oleg.set("cams", cams)
	else:
		push_error("OlegTheCat node was not found under Enemies.")

	var felix: AI = get_node_or_null("FelixTheWolf") as AI

	if felix == null:
		push_error("FelixTheWolf node was not found under Enemies or does not inherit AI.")
		return
	felix.ai_level = felix_level
	felix.character = 1
	if felix.camera == null:
		if cams != null: felix.camera = cams
		else:
			push_warning("Cameras node not found at ../Cam_Sys/Cam_Buttons, Felix visual state sync is disabled.")

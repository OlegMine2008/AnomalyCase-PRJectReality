extends SpotLight3D

var is_on = false
var cam_on = false
var mouse_pos = Vector2()
var sensitivity = 2

func _ready():
	is_on = false
	self.visible = is_on
	var _initial_rotation = rotation

func _input(event):
	# Переключение прожектора
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and not cam_on:
			is_on = !is_on
			self.visible = is_on
	
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		update_light_rotation()
	
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			cam_on = !cam_on
			is_on = false
			self.visible = is_on

func update_light_rotation():	
	# Получаем размер окна
	var viewport_size = get_viewport().size
	
	if viewport_size.x == 0 or viewport_size.y == 0:
		return
	
	# Преобразуем позицию мыши в диапазон -1..1
	var mouse_normalized = Vector2(
		(mouse_pos.x / viewport_size.x) * 2.0 - 1.0,
		(mouse_pos.y / viewport_size.y) * 2.0 - 1.0
	)
	
	# Поворачиваем прожектор (ограничиваем углы)
	# Для вертикали используем меньший диапазон, чтобы не светить вверх/вниз слишком сильно
	rotation.x = clamp(-mouse_normalized.y * sensitivity, -0.8, 0.8)
	rotation.y = clamp(-mouse_normalized.x * sensitivity, -1.5, 1.5)

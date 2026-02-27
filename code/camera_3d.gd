class_name Office
extends Camera3D

var max_rotation_angle = 90.0
var rotation_smoothness = 0.1
@export var position_epsilon := 0.01
@export var rotation_epsilon := deg_to_rad(0.5)

var target_rotation_y = 0.0
var current_rotation_y = 0.0
var z_pos = 0.0
var y_pos = 0.0
var x_pos = 0.0
var target_pos := Vector3.ZERO

var cams_on = false
var mouse_pos = Vector2()
var cam_transition_done = false

func _ready():
	current_rotation_y = rotation.y
	target_rotation_y = rotation.y
	position.x = x_pos
	position.y = y_pos
	position.z = z_pos
	target_pos = Vector3(x_pos, y_pos, z_pos)

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.position
	
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			cams_on = !cams_on
			if cams_on:
				# Координаты для приближения
				x_pos = -0.196
				y_pos = -0.88
				z_pos = -2.547
				target_rotation_y = 0.0
			else:
				# Возврат на начальные координаты
				x_pos = 0.0
				y_pos = 0.0
				z_pos = 0.0

func _process(_delta):
	# Плавное движение камеры к целевым координатам
	position.x = lerp(position.x, x_pos, rotation_smoothness)
	position.y = lerp(position.y, y_pos, rotation_smoothness)
	position.z = lerp(position.z, z_pos, rotation_smoothness)
	target_pos = Vector3(x_pos, y_pos, z_pos)
	
	# Если cams_on включен, поворот возвращается к нулю
	if cams_on:
		current_rotation_y = lerp_angle(current_rotation_y, target_rotation_y, rotation_smoothness)
		rotation.y = current_rotation_y
	else:
		# Считаем отклонение мыши от центра экрана
		var viewport = get_viewport()
		var viewport_center = viewport.size / 2
		
		# Нормализуем горизонтальное смещение от центра
		var horizontal_offset = (mouse_pos.x - viewport_center.x) / viewport_center.x * -1
		horizontal_offset = clamp(horizontal_offset, -1.0, 1.0)
		
		# Целевой угол поворота
		target_rotation_y = deg_to_rad(max_rotation_angle * horizontal_offset)
		
		# Плавная интерполяция
		current_rotation_y = lerp_angle(current_rotation_y, target_rotation_y, rotation_smoothness)
		
		# Применяем поворот
		rotation.y = current_rotation_y

	# Проверяем, завершено ли движение (позиция + поворот)
	var position_done = position.distance_to(target_pos) <= position_epsilon
	var rotation_done = abs(wrapf(current_rotation_y - target_rotation_y, -PI, PI)) <= rotation_epsilon
	cam_transition_done = position_done and rotation_done

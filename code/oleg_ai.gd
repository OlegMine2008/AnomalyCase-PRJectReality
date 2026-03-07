extends Node

@export var cams: Cameras

# Уровень ИИ
var bdifficulty = 0
# Камеры
var eatery_calm = true
var eatery = false
var child = false
var kitchen = false
var corrid = false
var salvag = false
var way = false
var office = false
# Эти - для 3D пространства офиса, то есть слева-справа офиса и может ли атаковать
var officeleft = false
var officeright = false
var canjumpscare = false

# Пока пустая функция самого перемещения(обновить на лабиринтный алгоритм)
func b():
	pass
	if eatery_calm:
		var rng = randf_range( 1, 4)
		if rng >= 2:
			cams.set_camera_state('Eatery', 1)
		else:
			cams.set_camera_state('Eatery', 1)
	elif eatery:
		var rng = randf_range( 1, 4)
		if rng >= 2:
			_apply_room_transition("eatery_to_kitchen")
			cams.set_camera_state('Kitchen', 1)
		else:
			_apply_room_transition("eatery_to_storage")
			cams.set_camera_state('Storage', 1)
	elif child:
		# No bap animation node in this project: apply the same transition directly.
		_apply_room_transition("child_to_eatery")
		cams.set_camera_state('Eatery', 1)
	elif kitchen:
		var rng = randf_range( 1, 4)
		if rng >= 2:
			_apply_room_transition("kitchen_to_corrid")
			# corrid
			cams.set_camera_state('Corr', 1)
	elif salvag:
		var rng = randf_range( 1, 4)
		if rng >= 2:
			_apply_room_transition("storage_to_way")
			# way
			cams.set_camera_state('Corr', 1)
	elif corrid or way:
		# К офису
		var rng = randf_range( 1, 4)
		if rng >= 2:
			_apply_room_transition("corrid_to_office")


# Updates only Oleg position flags.
# We keep partial flag updates (no global reset) to preserve current behavior.
# Transition names are room-based because old 3D animation keys are not used here.
func _apply_room_transition(transition: String) -> void:
	if transition == "eatery_to_kitchen":
		eatery = false
		kitchen = true
	elif transition == "eatery_to_storage":
		eatery = false
		salvag = true
	elif transition == "eatery_to_child":
		eatery = false
		child = true
	elif transition == "child_to_eatery":
		child = false
		eatery = true
	elif transition == "kitchen_to_eatery":
		kitchen = false
		eatery = true
	elif transition == "corrid_to_office":
		corrid = false
		office = true
	elif transition == "storage_to_kitchen":
		salvag = false
		kitchen = true
	elif transition == "office_to_eatery":
		canjumpscare = false
		office = false
		eatery = true
	elif transition == "office_ready_jumpscare":
		canjumpscare = true
		office = false
	elif transition == "kitchen_to_corrid":
		kitchen = false
		corrid = true
	elif transition == "storage_to_way":
		salvag = false
		way = true

# Сам процесс интеллекта
func _on_btimer_timeout():
	var rng = randf_range(1, 20)
	if rng <= bdifficulty:
		b()

# Сброс до начальных позиций?
#func bdisable():
#	$bap.stop()
#	salvag = false
#	eatery = false
#	office = false
#	kitchen = false
#	corrid = false
#	canjumpscare = false
#	eatery = true
#	$bap.play("RESET")

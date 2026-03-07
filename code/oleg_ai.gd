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
			cams.set_camera_state('Kitchen', 1)
		else:
			cams.set_camera_state('Storage', 1)
#	elif child == true:
#		$bap.play("backstagetodiningarea")
	elif kitchen:
		var rng = randf_range( 1, 4)
		if rng >= 2:
			# corrid
			cams.set_camera_state('Corr', 1)
	elif salvag:
		var rng = randf_range( 1, 4)
		if rng >= 2:
			# way
			cams.set_camera_state('Corr', 1)
	elif corrid or way:
		# К офису
		var rng = randf_range( 1, 4)
		if rng >= 2:
			pass


# Смена позиций в переменных
func _on_bap_animation_started(anim):
	if anim == "mainstagetodiningarea":
		eatery = false
		kitchen = true
	elif anim == "mainstagetobackstage":
		eatery = false
		salvag = true
	elif anim == "diningareatowesthall":
		eatery = false
		child = true
	elif anim == "backstagetodiningarea":
		child = false
		eatery = true
	elif anim == "supplyclosettodiningarea":
		kitchen = false
		eatery = true
	elif anim == "supplyclosettooffice":
		corrid = false
		office = true
	elif anim == "westhalltosupplycloset":
		salvag = false
		kitchen = true
	elif anim == "officetomainstage":
		canjumpscare = false
		office = false
		eatery = true
	elif anim == "readyjumpscare":
		canjumpscare = true
		office = false

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

# Тут скорее всего в оригинальном коде - местоположение и видимость для игрока
#func one_two():
#	if $"../../player".currentcam == 1 or $"../../player".currentcam == 2:
#		$"../../player".camstatic()

#func two_three():
#	if $"../../player".currentcam == 2 or $"../../player".currentcam == 3:
#		$"../../player".camstatic()

#func one_three():
#	if $"../../player".currentcam == 1 or $"../../player".currentcam == 3:
#		$"../../player".camstatic()

#func two_six():
#	if $"../../player".currentcam == 2 or $"../../player".currentcam == 6:
#		$"../../player".camstatic()

#func one_seven():
#	if $"../../player".currentcam == 1 or $"../../player".currentcam == 7:
#		$"../../player".camstatic()

#func two_five():
#	if $"../../player".currentcam == 2 or $"../../player".currentcam == 5:
#		$"../../player".camstatic()

#func five_seven():
#	if $"../../player".currentcam == 5 or $"../../player".currentcam == 7:
#		$"../../player".camstatic()

#func three():
#	if $"../../player".currentcam == 3:
#		$"../../player".camstatic()

#func six_seven():
#	if $"../../player".currentcam == 6 or $"../../player".currentcam == 7:
#		$"../../player".camstatic()

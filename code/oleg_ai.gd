extends Node

@export var cams: Cameras

var bdifficulty = 0
var eatery = true
var child = false
var kitchen = false
var corrid = false
var salvag = false
var way = false
var office = false
var canjumpscare = false

func b():
	if eatery:
		var rng = randf_range( 1, 4)
		if rng >= 2:
			cams.set_camera_state('Eatery', 1)
		else:
			$bap.play("mainstagetobackstage")
	elif kitchen:
		var rng = randf_range( 1, 4)
		if rng >= 2:
			$bap.play("diningareatowesthall")
		else:
			$bap.play("diningareatobackstage")
	elif child == true:
		$bap.play("backstagetodiningarea")
	elif corrid == true:
		var rng = randf_range( 1, 4)
		if rng >= 2:
			$bap.play("supplyclosettooffice")
		else:
			$bap.play("supplyclosettodiningarea")
	elif office == true:
		$bap.play("readyjumpscare")
	elif canjumpscare and $"../../interactable/leftredofficebutton".on == false:
		$"../../player".camcanrotate = false
		if $"../../player".camopen:
			$"../../player/cameratabap".play("cameratabclose2")
		$"../../player/effects/camtransitionap".play("camtransition2")
		$bap.play("jumpscare")
	elif canjumpscare and $"../../interactable/leftredofficebutton".on:
		$"../../player/doorhit".play()
		$bap.play("officetomainstage")

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

func _on_btimer_timeout():
	var rng = randf_range(1, 20)
	if rng <= bdifficulty:
		b()

func bdisable():
	$bap.stop()
	salvag = false
	eatery = false
	office = false
	kitchen = false
	corrid = false
	canjumpscare = false
	eatery = true
	$bap.play("RESET")

func one_two():
	if $"../../player".currentcam == 1 or $"../../player".currentcam == 2:
		$"../../player".camstatic()

func two_three():
	if $"../../player".currentcam == 2 or $"../../player".currentcam == 3:
		$"../../player".camstatic()

func one_three():
	if $"../../player".currentcam == 1 or $"../../player".currentcam == 3:
		$"../../player".camstatic()

func two_six():
	if $"../../player".currentcam == 2 or $"../../player".currentcam == 6:
		$"../../player".camstatic()

func one_seven():
	if $"../../player".currentcam == 1 or $"../../player".currentcam == 7:
		$"../../player".camstatic()

func two_five():
	if $"../../player".currentcam == 2 or $"../../player".currentcam == 5:
		$"../../player".camstatic()

func five_seven():
	if $"../../player".currentcam == 5 or $"../../player".currentcam == 7:
		$"../../player".camstatic()

func three():
	if $"../../player".currentcam == 3:
		$"../../player".camstatic()

func six_seven():
	if $"../../player".currentcam == 6 or $"../../player".currentcam == 7:
		$"../../player".camstatic()

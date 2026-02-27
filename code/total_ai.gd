class_name AI
extends Node

enum State {ABSENT, PRESENT, ALT_1, ALT_2}

@export_enum("Red", "Green") var character: int
@export var camera: Cameras

var ai_level: int
var step: int
var current_room: int

func has_passed_check() -> bool:
	# Handles whether character moves or not (depending on char_level)
	return ai_level >= randi_range(1,20)

func _is_room_empty(room: int) -> bool:
	if camera == null:
		return false
	if not _has_property(camera, "rooms"):
		return false
	return camera.rooms[room].max() == State.ABSENT

func move_check() -> void:
	if has_passed_check():
		move_options()

func move_options() -> void:
	pass

func move_to(target_room: int, new_state: int = State.PRESENT, move_step: int = 1) -> void:
	# Handles character movement from one room to another
	# And character state changes in a room (handled by new_state)
	step += move_step

	if camera != null and _has_property(camera, "rooms"):
		camera.rooms[current_room][character] = State.ABSENT
		camera.rooms[target_room][character] = new_state
	
	camera.set_camera_state('current_room', 2)

	if camera != null and camera.has_method("update_feeds"):
		camera.update_feeds([current_room, target_room])
	current_room = target_room

func _has_property(target: Object, property_name: String) -> bool:
	for prop in target.get_property_list():
		if prop["name"] == property_name:
			return true
	return false

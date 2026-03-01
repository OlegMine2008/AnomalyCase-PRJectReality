class_name AI
extends Node

enum State {ABSENT, PRESENT, ALT_1, ALT_2}

@export_enum("OlegTheCat", "FelixTheWolf") var character: int
@export var camera: Cameras

var ai_level: int
var step: int
var current_room: int

func has_passed_check() -> bool:
	# Handles whether character moves or not (depending on char_level)
	return ai_level >= randi_range(1,20)

func _get_camera_room_name(_room: int) -> String:
	# Must be implemented by concrete AI scripts.
	return ""

func _self_camera_state() -> int:
	# Cameras.gd: 1 = Oleg, 2 = Felix, 3 = Every
	return 1 if character == 0 else 2

func _other_camera_state() -> int:
	return 2 if character == 0 else 1

func _get_room_state(room: int) -> int:
	if camera == null or not _has_property(camera, "current_camera_state"):
		return State.ABSENT

	var room_name: String = _get_camera_room_name(room)
	if room_name.is_empty():
		return State.ABSENT

	var states: Dictionary = camera.current_camera_state
	if not states.has(room_name):
		return State.ABSENT

	return int(states[room_name])

func _set_room_state(room: int, state_index: int) -> void:
	if camera == null:
		return
	if not camera.has_method("set_camera_state"):
		return

	var room_name: String = _get_camera_room_name(room)
	if room_name.is_empty():
		return

	camera.set_camera_state(room_name, state_index)

func _is_room_empty(room: int) -> bool:
	# If there is no camera binding yet, do not block AI movement.
	if camera == null:
		return true
	return _get_room_state(room) == State.ABSENT

func move_check() -> void:
	if has_passed_check():
		move_options()

func move_options() -> void:
	pass

func move_to(target_room: int, new_state: int = State.PRESENT, move_step: int = 1) -> void:
	# Handles character movement from one room to another
	# And character state changes in a room (handled by new_state)
	step += move_step
	var previous_room: int = current_room

	if camera != null:
		# Compatibility with old API if a rooms array exists.
		if _has_property(camera, "rooms"):
			camera.rooms[previous_room][character] = State.ABSENT
			camera.rooms[target_room][character] = new_state

		# Sync with current Cameras.gd state model.
		var from_state: int = _get_room_state(previous_room)
		if from_state == _self_camera_state():
			_set_room_state(previous_room, State.ABSENT)
		elif from_state == State.ALT_2:
			_set_room_state(previous_room, _other_camera_state())

		var to_state: int = _get_room_state(target_room)
		if to_state == State.ABSENT:
			_set_room_state(target_room, _self_camera_state())
		elif to_state == _other_camera_state():
			_set_room_state(target_room, State.ALT_2)

		if camera.has_method("update_feeds"):
			camera.update_feeds([previous_room, target_room])
	current_room = target_room

func _has_property(target: Object, property_name: String) -> bool:
	for prop in target.get_property_list():
		if prop["name"] == property_name:
			return true
	return false

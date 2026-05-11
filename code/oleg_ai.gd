extends Node

@export var cams: Cameras
@onready var oleg_time: Timer = $OlegTime

const STATE_EMPTY := 0
const STATE_OLEG := 1
const STATE_FELIX := 2
const STATE_EVERY := 3

const LOGIC_TO_CAMERA_ROOM := {
	"Lab": "Back",
	"Secret": "Back",
}

var bdifficulty = 0
var real_cur = "Eatery"
var real_prev = ""
var vision_cur = real_cur
var vision_prev = real_prev
var true_vision := false
var is_desynced = false
var methode = "go_real"
var officeleft = false
var officeright = false
var canjumpscare = false

var rooms = {
	"Eatery": ["Kitchen", "Storage", "Kids"],
	"Kitchen": ["Eatery", "Corr", "Lab"],
	"Storage": ["Eatery", "Way", "Secret"],
	"Corr": ["Kitchen", "Office"],
	"Way": ["Storage", "Office"],
	"Lab": ["Kitchen", "Behind"],
	"Secret": ["Storage", "Behind"],
	"Behind": ["Lab", "Secret", "Office"],
	"Office": ["Corr", "Way"],
}

func b():
	var next = _get_next_room(real_cur, real_prev)
	_apply_vision_move(next)

	real_prev = real_cur
	real_cur = next
	if true_vision:
		_sync_camera_move(real_prev, real_cur)
	print("В реальности Олег находится в ", real_cur)

func _apply_vision_move(next_room: String) -> void:
	if is_desynced and methode == "go_real":
		return

	vision_prev = vision_cur
	vision_cur = next_room
	if not true_vision:
		_sync_camera_move(vision_prev, vision_cur)

func _get_next_room(current_room: String, previous_room: String) -> String:
	if not rooms.has(current_room):
		return ""

	if current_room == "Office":
		return _choose_next_room(_get_office_candidates(previous_room))

	var neighbors: Array = rooms[current_room]
	var filtered_neighbors: Array[String] = _filter_neighbors(neighbors, previous_room)
	return _choose_next_room(filtered_neighbors)

func _get_office_candidates(previous_room: String) -> Array[String]:
	if previous_room == "Behind":
		return ["Behind"]
	return ["Corr", "Way"]

func _filter_neighbors(neighbors: Array, previous_room: String) -> Array[String]:
	var source_neighbors: Array[String] = []
	for neighbor in neighbors:
		if neighbor is String:
			source_neighbors.append(neighbor)

	if source_neighbors.is_empty():
		return []

	var candidate_neighbors: Array[String] = []
	for neighbor in source_neighbors:
		if neighbor != previous_room:
			candidate_neighbors.append(neighbor)
	if candidate_neighbors.is_empty():
		candidate_neighbors = source_neighbors.duplicate()

	var best_distance := INF
	var best_neighbors: Array[String] = []
	for neighbor in candidate_neighbors:
		var distance := _get_distance_to_office(neighbor)
		if distance < best_distance:
			best_distance = distance
			best_neighbors = [neighbor]
		elif is_equal_approx(distance, best_distance):
			best_neighbors.append(neighbor)

	return best_neighbors

func _choose_next_room(neighbors: Array[String]) -> String:
	if neighbors.is_empty():
		return ""
	if neighbors.size() == 1:
		return neighbors[0]
	return neighbors[randi_range(0, neighbors.size() - 1)]

func _get_distance_to_office(start_room: String) -> float:
	if start_room == "Office":
		return 0.0
	if not rooms.has(start_room):
		return INF

	var visited := {start_room: true}
	var queue: Array[Dictionary] = [{"room": start_room, "distance": 0}]

	while not queue.is_empty():
		var current_step: Dictionary = queue.pop_front()
		var room_name: String = current_step["room"]
		var distance: int = current_step["distance"]

		if room_name == "Office":
			return float(distance)
		if not rooms.has(room_name):
			continue

		for neighbor in rooms[room_name]:
			if not (neighbor is String):
				continue
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			queue.append({"room": neighbor, "distance": distance + 1})

	return INF

func _get_camera_room_name(room_name: String) -> String:
	if LOGIC_TO_CAMERA_ROOM.has(room_name):
		return String(LOGIC_TO_CAMERA_ROOM[room_name])
	return room_name

func _get_room_state(room_name: String) -> int:
	room_name = _get_camera_room_name(room_name)
	if cams == null:
		return STATE_EMPTY
	if not cams.current_camera_state.has(room_name):
		return STATE_EMPTY
	return int(cams.current_camera_state[room_name])

func _sync_camera_move(from_room: String, to_room: String) -> void:
	if cams == null and not _ensure_cams():
		return

	var from_camera_room := _get_camera_room_name(from_room)
	var to_camera_room := _get_camera_room_name(to_room)
	if from_camera_room == to_camera_room:
		return

	if from_camera_room != "":
		var from_state := _get_room_state(from_camera_room)
		if from_state == STATE_OLEG:
			cams.set_camera_state(from_camera_room, STATE_EMPTY)
		elif from_state == STATE_EVERY:
			cams.set_camera_state(from_camera_room, STATE_FELIX)

	if to_camera_room == "":
		return

	var to_state := _get_room_state(to_camera_room)
	if to_state == STATE_EMPTY:
		cams.set_camera_state(to_camera_room, STATE_OLEG)
	elif to_state == STATE_FELIX:
		cams.set_camera_state(to_camera_room, STATE_EVERY)

func set_true_vision(enabled: bool) -> void:
	if true_vision == enabled:
		return

	if not _ensure_cams():
		true_vision = enabled
		return

	if enabled:
		_sync_camera_move(vision_cur, real_cur)
	else:
		_sync_camera_move(real_cur, vision_cur)

	true_vision = enabled

func _ensure_cams() -> bool:
	if cams != null:
		return true
	cams = get_node_or_null("../../Cam_Sys/Cam_Buttons") as Cameras
	return cams != null

func _ready() -> void:
	if oleg_time == null:
		push_error("OlegTime timer was not found under OlegTheCat.")
		return
	if not oleg_time.timeout.is_connected(_on_oleg_time_timeout):
		oleg_time.timeout.connect(_on_oleg_time_timeout)
	if oleg_time.wait_time <= 0.0:
		oleg_time.wait_time = 3.0
	oleg_time.autostart = true
	if oleg_time.is_stopped():
		oleg_time.start()

	real_cur = "Eatery"
	real_prev = ""

func _on_oleg_time_timeout() -> void:
	if randf_range(1, 21) < bdifficulty:
		b()
	if real_cur == "Office":
		is_desynced = false
		return
	if not is_desynced and randf_range(bdifficulty, 101) > (bdifficulty * 5):
		is_desynced = true
		print("Рассинхронизация противника - ", is_desynced)

func _on_btimer_timeout() -> void:
	_on_oleg_time_timeout()

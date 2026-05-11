extends AI

enum Room {Eatery, Storage, Way, Kitchen, Secret, Lab, Behind, Office, Corr}
enum Route {VIA_SECRET, VIA_LAB}

const NO_ROUTE: int = -1
const PATHS_TO_OFFICE := {
	Route.VIA_SECRET: [Room.Storage, Room.Secret, Room.Behind, Room.Office],
	Route.VIA_LAB: [Room.Kitchen, Room.Lab, Room.Behind, Room.Office],
}

var current_route: int = NO_ROUTE
var phase: int = 0
var last_room: int = Room.Eatery

@onready var felix_time: Timer = $FelixTime

func _ready() -> void:
	step = 0
	phase = 0
	current_room = Room.Eatery
	last_room = Room.Eatery
	current_route = NO_ROUTE

	if felix_time == null:
		push_error("FelixTime timer was not found under FelixTheWolf.")
		return

	if not felix_time.timeout.is_connected(_on_felix_time_timeout):
		felix_time.timeout.connect(_on_felix_time_timeout)

	if felix_time.wait_time <= 0.0:
		felix_time.wait_time = 3.0

	felix_time.autostart = true
	if felix_time.is_stopped():
		felix_time.start()

func _on_felix_time_timeout() -> void:
	move_check()

func _get_camera_room_name(room: int) -> String:
	match room:
		Room.Eatery:
			return "Eatery"
		Room.Storage:
			return "Storage"
		Room.Way:
			return "Way"
		Room.Kitchen:
			return "Kitchen"
		Room.Secret:
			return "Back"
		Room.Lab:
			return "Back"
		Room.Behind:
			return "Behind"
		Room.Corr:
			return "Corr"
		_:
			return ""

func _get_route_path(route: int) -> Array:
	if not PATHS_TO_OFFICE.has(route):
		return []
	return PATHS_TO_OFFICE[route]

func _pick_next_from_office(previous_room: int) -> int:
	if previous_room == Room.Behind:
		return Room.Behind
	return [Room.Corr, Room.Way][randi_range(0, 1)]

func _reset_cycle() -> void:
	phase = 0
	step = 0
	current_route = NO_ROUTE

func _move_to_room(target_room: int, log_name: String = "") -> void:
	var prev := current_room
	move_to(target_room)
	last_room = prev
	if log_name.is_empty():
		log_name = _get_camera_room_name(target_room)
	print("Felix moved to %s" % log_name)

func move_options() -> void:
	if phase == 0:
		if current_route == NO_ROUTE:
			current_route = randi_range(Route.VIA_SECRET, Route.VIA_LAB)

		var path_to_office: Array = _get_route_path(current_route)
		if path_to_office.is_empty():
			_reset_cycle()
			return

		if step < path_to_office.size():
			var target_room: int = int(path_to_office[step])
			if _is_room_empty(target_room):
				_move_to_room(target_room)
				if target_room == Room.Office:
					phase = 1
			return

		phase = 1

	if phase == 1:
		var office_exit: int = _pick_next_from_office(last_room)
		if _is_room_empty(office_exit):
			_move_to_room(office_exit)
			phase = 2
		return

	if phase == 2:
		if _is_room_empty(Room.Eatery):
			var prev := current_room
			move_to(Room.Eatery, State.PRESENT, -step)
			last_room = prev
			print("Felix moved to Eatery")
			_reset_cycle()

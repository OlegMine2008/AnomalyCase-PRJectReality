extends AI

enum Room {Eatery, Storage, Way, Kitchen}
enum Route {VIA_STORAGE, VIA_KITCHEN}

const NO_ROUTE: int = -1

var current_route: int = NO_ROUTE

@onready var felix_time: Timer = $FelixTime

func _ready() -> void:
	step = 0
	current_room = Room.Eatery
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
			return "Corr"
		Room.Kitchen:
			return "Kitchen"
		_:
			return ""

func _get_first_room_for_route(route: int) -> int:
	if route == Route.VIA_STORAGE:
		return Room.Storage
	return Room.Kitchen

func move_options() -> void:
	match step:
		0:
			if current_route == NO_ROUTE:
				current_route = randi_range(Route.VIA_STORAGE, Route.VIA_KITCHEN)

			var first_room: int = _get_first_room_for_route(current_route)
			if _is_room_empty(first_room):
				move_to(first_room)
				print("Felix moved to %s" % _get_camera_room_name(first_room))
		1:
			if _is_room_empty(Room.Way):
				move_to(Room.Way)
				print("Felix moved to Way")
		2:
			move_to(Room.Eatery, State.PRESENT, -step)
			current_route = NO_ROUTE
			print("Felix moved to Eatery")
		_:
			# Defensive reset if step gets out of expected range.
			step = 0
			current_route = NO_ROUTE

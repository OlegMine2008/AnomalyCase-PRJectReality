extends AI

enum Room {Eatery, Storage, Way, Kitchen, Secret, Lab, Behind, Office, Corr}
enum Route {VIA_SECRET, VIA_LAB}

const STATE_EMPTY := 0
const STATE_OLEG := 1
const STATE_FELIX := 2
const STATE_EVERY := 3

const NO_ROUTE: int = -1
const PATHS_TO_OFFICE := {
	Route.VIA_SECRET: [Room.Storage, Room.Secret, Room.Behind, Room.Office],
	Route.VIA_LAB: [Room.Kitchen, Room.Lab, Room.Behind, Room.Office],
}
const LOGIC_TO_CAMERA_ROOM := {
	Room.Secret: "Secret",
	Room.Lab: "Lab",
}
const DESYNC_TRIGGER_ROOMS := [Room.Secret, Room.Lab]

# Поддержанные режимы рассинхрона:
# go_real - двигается real-слой, vision может "замереть";
# остальные режимы оставлены для совместимости и расширения.
const METHOD_GO_REAL := "go_real"
const METHOD_GO_VISION := "go_vision"
const METHOD_VISION_FORWARD := "vision_forward"
const METHOD_REAL_FORWARD := "real_forward"
const SUPPORTED_METHODS := [
	METHOD_GO_REAL,
	METHOD_GO_VISION,
	METHOD_VISION_FORWARD,
	METHOD_REAL_FORWARD,
]

var current_route: int = NO_ROUTE
var phase: int = 0
var last_room: int = Room.Eatery

var real_cur: int = Room.Eatery
var real_prev: int = Room.Eatery
var vision_cur: int = Room.Eatery
var vision_prev: int = Room.Eatery
var true_vision := false
var is_desynced := false
var methode := METHOD_GO_REAL

@onready var felix_time: Timer = $FelixTime

# Инициализирует стартовую позицию Felix и запускает таймер его логики.
func _ready() -> void:
	step = 0
	phase = 0
	current_room = Room.Eatery
	last_room = Room.Eatery
	current_route = NO_ROUTE

	real_cur = Room.Eatery
	real_prev = Room.Eatery
	vision_cur = Room.Eatery
	vision_prev = Room.Eatery

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

	if not SUPPORTED_METHODS.has(methode):
		set_methode(methode)

# Обрабатывает тик Felix: движение по шансу и сброс рассинхрона в Office.
func _on_felix_time_timeout() -> void:
	move_check()
	if real_cur == Room.Office:
		is_desynced = false

# Возвращает имя camera feed для логической комнаты Felix.
func _get_camera_room_name(room: int) -> String:
	if LOGIC_TO_CAMERA_ROOM.has(room):
		return String(LOGIC_TO_CAMERA_ROOM[room])

	match room:
		Room.Eatery:
			return "Eatery"
		Room.Storage:
			return "Storage"
		Room.Way:
			return "Way"
		Room.Kitchen:
			return "Kitchen"
		Room.Behind:
			return "Behind"
		Room.Corr:
			return "Corr"
		_:
			return ""

# Возвращает маршрут до офиса для выбранной ветки.
func _get_route_path(route: int) -> Array:
	if not PATHS_TO_OFFICE.has(route):
		return []
	return PATHS_TO_OFFICE[route]

# Выбирает комнату выхода из Office с учётом предыдущей позиции.
func _pick_next_from_office(previous_room: int) -> int:
	if previous_room == Room.Behind:
		return Room.Behind
	return [Room.Corr, Room.Way][randi_range(0, 1)]

# Сбрасывает фазу цикла Felix для нового захода на маршрут.
func _reset_cycle() -> void:
	phase = 0
	step = 0
	current_route = NO_ROUTE

# Возвращает true, если вход в комнату должен принудительно включить рассинхрон.
func _is_desync_trigger_room(room: int) -> bool:
	return DESYNC_TRIGGER_ROOMS.has(room)

# Активирует рассинхрон Felix.
func _enable_desync(reason: String) -> void:
	if is_desynced:
		return
	is_desynced = true
	print("Felix desync enabled (%s)" % reason)

# Пытается включить рассинхрон (сейчас используется принудительный триггер от комнат).
func _try_enable_desync(force_enable: bool = false) -> void:
	if is_desynced:
		return
	if force_enable:
		_enable_desync("room_trigger")

# Возвращает состояние комнаты в системе камер.
func _get_room_state(room: int) -> int:
	if camera == null:
		return STATE_EMPTY
	var room_name := _get_camera_room_name(room)
	if room_name.is_empty():
		return STATE_EMPTY
	if not camera.current_camera_state.has(room_name):
		return STATE_EMPTY
	return int(camera.current_camera_state[room_name])

# Гарантирует наличие ссылки на Cameras.
func _ensure_camera() -> bool:
	if camera != null:
		return true
	camera = get_node_or_null("../../Cam_Sys/Cam_Buttons") as Cameras
	return camera != null

func _room_supports_every_state(camera_room: String) -> bool:
	if camera == null:
		return false
	if not camera.CAMERAS_IMAGES.has(camera_room):
		return false
	var room_states: Dictionary = camera.CAMERAS_IMAGES[camera_room]
	return room_states.has("Every")

func _get_display_room() -> int:
	return real_cur if true_vision else vision_cur

# Полная пересборка не даёт Felix застревать в старом слое после смены режима.
func _resync_camera_presence() -> void:
	if camera == null and not _ensure_camera():
		return

	var display_room := _get_display_room()
	var display_camera_room := _get_camera_room_name(display_room)
	var affected_camera_rooms: Dictionary[String, bool] = {}

	for room_name in camera.current_camera_state.keys():
		var camera_room := String(room_name)
		affected_camera_rooms[camera_room] = true
		var state := int(camera.current_camera_state[camera_room])
		if state == STATE_FELIX:
			camera.set_camera_state(camera_room, STATE_EMPTY)
		elif state == STATE_EVERY:
			camera.set_camera_state(camera_room, STATE_OLEG)

	if display_camera_room == "":
		for camera_room in affected_camera_rooms.keys():
			camera.refresh_camera_feed(camera_room, true)
		return

	var display_state := _get_room_state(display_room)
	if display_state == STATE_EMPTY:
		camera.set_camera_state(display_camera_room, STATE_FELIX)
	elif display_state == STATE_OLEG and _room_supports_every_state(display_camera_room):
		camera.set_camera_state(display_camera_room, STATE_EVERY)

	affected_camera_rooms[display_camera_room] = true
	for camera_room in affected_camera_rooms.keys():
		camera.refresh_camera_feed(camera_room, true)

# Синхронизирует перемещение Felix в camera-состояниях (from -> to).
func _sync_camera_move(from_room: int, to_room: int) -> void:
	if camera == null and not _ensure_camera():
		return

	var from_camera_room := _get_camera_room_name(from_room)
	var to_camera_room := _get_camera_room_name(to_room)
	if from_camera_room == to_camera_room:
		return

	if from_camera_room != "":
		var from_state := _get_room_state(from_room)
		if from_state == STATE_FELIX:
			camera.set_camera_state(from_camera_room, STATE_EMPTY)
		elif from_state == STATE_EVERY:
			camera.set_camera_state(from_camera_room, STATE_OLEG)

	if to_camera_room == "":
		return

	var to_state := _get_room_state(to_room)
	if to_state == STATE_EMPTY:
		camera.set_camera_state(to_camera_room, STATE_FELIX)
	elif to_state == STATE_OLEG and _room_supports_every_state(to_camera_room):
		camera.set_camera_state(to_camera_room, STATE_EVERY)

# Обновляет vision-позицию Felix и двигает её на камерах, если активен seen-режим.
func _apply_vision_move(next_room: int) -> void:
	if is_desynced and methode == METHOD_GO_REAL:
		return

	vision_prev = vision_cur
	vision_cur = next_room
	if not true_vision:
		_resync_camera_presence()

# Выполняет один шаг Felix с разделением real/vision слоёв.
func _move_to_room(target_room: int, move_step: int = 1, log_name: String = "") -> void:
	_apply_vision_move(target_room)

	real_prev = real_cur
	real_cur = target_room
	current_room = real_cur
	last_room = real_prev
	step += move_step

	if true_vision:
		_resync_camera_presence()

	if log_name.is_empty():
		log_name = _get_camera_room_name(target_room)
	print("Felix moved to %s" % log_name)

	_try_enable_desync(_is_desync_trigger_room(real_cur))

# Выбирает и выполняет следующий шаг Felix в рамках его фазового маршрута.
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
			_move_to_room(Room.Eatery, -step, "Eatery")
			_reset_cycle()

# Переключает режим отображения позиции Felix на камерах (vision/real).
func set_true_vision(enabled: bool) -> void:
	if true_vision == enabled:
		return

	if not _ensure_camera():
		true_vision = enabled
		return

	true_vision = enabled
	_resync_camera_presence()

# Публичный setter режима methode с валидацией допустимых значений.
func set_methode(mode: String) -> void:
	if SUPPORTED_METHODS.has(mode):
		methode = mode
		return
	push_warning("Unsupported methode: %s. Fallback to %s." % [mode, METHOD_GO_REAL])
	methode = METHOD_GO_REAL

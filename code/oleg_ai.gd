extends Node

@export var cams: Cameras
@onready var oleg_time: Timer = $OlegTime

const STATE_EMPTY := 0
const STATE_OLEG := 1
const STATE_FELIX := 2
const STATE_EVERY := 3
const DESYNC_COOLDOWN_MOVES := 3
const DESYNC_MIN_CHANCE := 0.12
const DESYNC_MAX_CHANCE := 0.42

const LOGIC_TO_CAMERA_ROOM := {
	"Lab": "Back",
	"Secret": "Back",
}
const DESYNC_TRIGGER_ROOMS := ["Lab", "Secret", "Behind"]

# Подготовленные режимы method(e):
# go_* - двигается только указанный слой (второй может быть "заморожен" в будущем);
# *_forward - в будущем режим "расхождения маршрутов" для real/vision.
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

var bdifficulty = 0
var real_cur = "Eatery"
var real_prev = ""
var vision_cur = real_cur
var vision_prev = real_prev
var true_vision := false
var is_desynced = false
var methode = METHOD_GO_REAL
var officeleft = false
var officeright = false
var canjumpscare = false
var _moves_since_desync := DESYNC_COOLDOWN_MOVES

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

# Выполняет один шаг AI:
# считает следующую комнату, синхронизирует vision-слой и затем real-слой.
func b():
	var next = _get_next_room(real_cur, real_prev)
	if next == "":
		return

	_apply_vision_move(next)

	real_prev = real_cur
	real_cur = next
	_moves_since_desync += 1
	if true_vision:
		_sync_camera_move(real_prev, real_cur)
	print("В реальности Олег находится в ", real_cur)
	_try_enable_desync(_is_desync_trigger_room(real_cur))

# Обновляет "видимую" (vision) позицию противника.
# Пока активен только текущий сценарий desync для go_real.
func _apply_vision_move(next_room: String) -> void:
	if is_desynced and methode == METHOD_GO_REAL:
		return

	vision_prev = vision_cur
	vision_cur = next_room
	if not true_vision:
		_sync_camera_move(vision_prev, vision_cur)

# Возвращает следующую логическую комнату для real-перемещения.
func _get_next_room(current_room: String, previous_room: String) -> String:
	if not rooms.has(current_room):
		return ""

	# Специальное правило выхода из Office.
	if current_room == "Office":
		return _choose_next_room(_get_office_candidates(previous_room))

	var neighbors: Array = rooms[current_room]
	var filtered_neighbors: Array[String] = _filter_neighbors(neighbors, previous_room)
	return _choose_next_room(filtered_neighbors)

# Формирует допустимые варианты выхода из Office.
func _get_office_candidates(previous_room: String) -> Array[String]:
	if previous_room == "Behind":
		return ["Behind"]
	return ["Corr", "Way"]

# Фильтрует соседей:
# 1) избегает мгновенного возврата, если есть альтернатива;
# 2) оставляет только кратчайшие пути до Office.
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

# Выбирает комнату из подготовленного списка кандидатов.
func _choose_next_room(neighbors: Array[String]) -> String:
	if neighbors.is_empty():
		return ""
	if neighbors.size() == 1:
		return neighbors[0]
	return neighbors[randi_range(0, neighbors.size() - 1)]

# Считает дистанцию до Office через BFS.
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

# Преобразует логическую комнату в имя camera feed.
func _get_camera_room_name(room_name: String) -> String:
	if LOGIC_TO_CAMERA_ROOM.has(room_name):
		return String(LOGIC_TO_CAMERA_ROOM[room_name])
	return room_name

# Возвращает текущее состояние комнаты в системе камер.
func _get_room_state(room_name: String) -> int:
	room_name = _get_camera_room_name(room_name)
	if cams == null:
		return STATE_EMPTY
	if not cams.current_camera_state.has(room_name):
		return STATE_EMPTY
	return int(cams.current_camera_state[room_name])

# Синхронизирует перемещение Oleg в состояниях камер (from -> to).
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

	# Страховка от "двойного присутствия": удаляем Oleg из всех прочих комнат.
	_clear_oleg_presence_except(to_camera_room)

	var to_state := _get_room_state(to_camera_room)
	if to_state == STATE_EMPTY:
		cams.set_camera_state(to_camera_room, STATE_OLEG)
	elif to_state == STATE_FELIX:
		if _room_supports_every_state(to_camera_room):
			cams.set_camera_state(to_camera_room, STATE_EVERY)
		else:
			# Если "Every" не поддержан текстурами комнаты, приоритет отдаём Oleg.
			cams.set_camera_state(to_camera_room, STATE_OLEG)

# Гарантированно оставляет Oleg только в одной комнате камеры.
func _clear_oleg_presence_except(except_camera_room: String) -> void:
	if cams == null:
		return
	for room_name in cams.current_camera_state.keys():
		var camera_room := String(room_name)
		if camera_room == except_camera_room:
			continue
		var state := int(cams.current_camera_state[camera_room])
		if state == STATE_OLEG:
			cams.set_camera_state(camera_room, STATE_EMPTY)
		elif state == STATE_EVERY:
			cams.set_camera_state(camera_room, STATE_FELIX)

# Проверяет, поддерживает ли конкретный camera feed состояние "Every".
func _room_supports_every_state(camera_room: String) -> bool:
	if cams == null:
		return false
	if not cams.CAMERAS_IMAGES.has(camera_room):
		return false
	var room_states: Dictionary = cams.CAMERAS_IMAGES[camera_room]
	return room_states.has("Every")

# Переключает режим отображения позиции Oleg на камерах (vision/real).
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

# Публичный setter для режима methode с валидацией допустимых значений.
func set_methode(mode: String) -> void:
	if SUPPORTED_METHODS.has(mode):
		methode = mode
		return
	push_warning("Unsupported methode: %s. Fallback to %s." % [mode, METHOD_GO_REAL])
	methode = METHOD_GO_REAL

# Гарантирует наличие ссылки на Cameras.
func _ensure_cams() -> bool:
	if cams != null:
		return true
	cams = get_node_or_null("../../Cam_Sys/Cam_Buttons") as Cameras
	return cams != null

# Инициализирует таймер и стартовые позиции AI.
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

	# На случай ручного изменения переменной в инспекторе.
	if not SUPPORTED_METHODS.has(methode):
		set_methode(methode)

	real_cur = "Eatery"
	real_prev = ""
	vision_cur = real_cur
	vision_prev = real_prev
	_moves_since_desync = DESYNC_COOLDOWN_MOVES

# Возвращает true, если вход в комнату должен принудительно включать рассинхрон.
func _is_desync_trigger_room(room_name: String) -> bool:
	return DESYNC_TRIGGER_ROOMS.has(room_name)

# Возвращает шанс рассинхрона от уровня ИИ в безопасных границах.
func _get_desync_chance_by_level() -> float:
	var normalized_level = clamp(float(bdifficulty) / 20.0, 0.0, 1.0)
	return lerpf(DESYNC_MIN_CHANCE, DESYNC_MAX_CHANCE, normalized_level)

# Активирует рассинхрон и сбрасывает кулдаун счётчика повторного включения.
func _enable_desync(reason: String) -> void:
	if is_desynced:
		return
	is_desynced = true
	_moves_since_desync = 0
	print("Рассинхронизация противника включена (%s)." % reason)

# Пытается включить рассинхрон: принудительно от комнаты или случайно от уровня.
func _try_enable_desync(force_enable: bool = false) -> void:
	if is_desynced:
		return
	if force_enable:
		_enable_desync("room_trigger")
		return
	if _moves_since_desync < DESYNC_COOLDOWN_MOVES:
		return
	if randf() <= _get_desync_chance_by_level():
		_enable_desync("random_roll")

# Обработчик тика AI: проверка шанса хода и логики рассинхрона.
func _on_oleg_time_timeout() -> void:
	if randf_range(1, 21) < bdifficulty:
		b()
	if real_cur == "Office":
		is_desynced = false
		return

# Совместимость со старыми подключениями сигнала.
func _on_btimer_timeout() -> void:
	_on_oleg_time_timeout()

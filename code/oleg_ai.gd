extends Node

@export var cams: Cameras
@onready var oleg_time: Timer = $OlegTime

const STATE_EMPTY := 0
const STATE_OLEG := 1
const STATE_FELIX := 2
const STATE_EVERY := 3

# Уровень ИИ
var bdifficulty = 0
# Позиции Oleg по комнатам
var real_cur = 'Eatery'
var real_prev = ''
var vision_cur = real_cur
var vision_prev = real_prev
# Флаги "истинной" реальности
var is_desynced = false
var methode = "go_real"
# Эти флаги пока не используются
var officeleft = false
var officeright = false
var canjumpscare = false

# Для лабиринтного алгоритма(комнаты и куда они ведут)
var rooms = {
  "Eatery": ["Kitchen", "Storage", "Kids"],
  "Kitchen": ["Eatery", "Corr"],
  "Storage": ["Eatery", "Way"],
  "Corr": ["Kitchen", "Office"],
  "Way": ["Storage", "Office"],
  "Office": ["Corr", "Way"]
}


# Основная логика перемещения:
# 1) считаем следующую комнату, 2) обрабатываем визуальный шаг,
# 3) двигаем реальное положение, 4) логируем итог.
func b():
	var next = _get_next_room(real_cur, real_prev)
	_apply_vision_move(next)

	real_prev = real_cur
	real_cur = next
	print('В реальности Олег находится в ', real_cur)

# Обновляет "видимое" положение:
# при desync + go_real визуальная позиция заморожена, иначе двигается синхронно.
func _apply_vision_move(next_room: String) -> void:
	if is_desynced and methode == "go_real":
		return

	vision_prev = vision_cur
	vision_cur = next_room
	_sync_camera_move(vision_prev, vision_cur)

# Получение комнаты
func _get_next_room(current_room: String, previous_room: String) -> String:
	# Общая точка входа: берём соседей, оставляем лучшие варианты и
	# затем делаем финальный выбор между равноценными комнатами.
	if not rooms.has(current_room):
		return ""

	var neighbors: Array = rooms[current_room]
	var filtered_neighbors: Array[String] = _filter_neighbors(neighbors, previous_room)
	return _choose_next_room(filtered_neighbors)

# Фильтрация ненужных комнат-соседей(поиск короткого пути)
func _filter_neighbors(neighbors: Array, previous_room: String) -> Array[String]:
	var source_neighbors: Array[String] = []
	for neighbor in neighbors:
		if neighbor is String:
			source_neighbors.append(neighbor)

	if source_neighbors.is_empty():
		return []

	# Сначала запрещаем мгновенный возврат назад, но не ценой тупика:
	# если после этого не остаётся вариантов, разрешаем идти обратно.
	var candidate_neighbors: Array[String] = []
	for neighbor in source_neighbors:
		if neighbor != previous_room:
			candidate_neighbors.append(neighbor)
	if candidate_neighbors.is_empty():
		candidate_neighbors = source_neighbors.duplicate()

	# Оставляем только комнаты с минимальной дистанцией до Office.
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

# Выбор наивыгоднейшей комнаты
func _choose_next_room(neighbors: Array[String]) -> String:
	# На этом этапе остаются только лучшие кандидаты.
	# Если их несколько, выбираем случайно, пока без весов.
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

func _get_room_state(room_name: String) -> int:
	if cams == null:
		return STATE_EMPTY
	if not cams.current_camera_state.has(room_name):
		return STATE_EMPTY
	return int(cams.current_camera_state[room_name])

func _sync_camera_move(from_room: String, to_room: String) -> void:
	# Убираем Oleg из предыдущей камеры с учетом Felix (Every -> Felix).
	if from_room != "":
		var from_state := _get_room_state(from_room)
		if from_state == STATE_OLEG:
			cams.set_camera_state(from_room, STATE_EMPTY)
		elif from_state == STATE_EVERY:
			cams.set_camera_state(from_room, STATE_FELIX)

	# Если целевой камеры нет (например, офис), на этом завершаем.
	if to_room == "":
		return

	# Ставим Oleg в целевую камеру с учетом Felix (Felix -> Every).
	var to_state := _get_room_state(to_room)
	if to_state == STATE_EMPTY:
		cams.set_camera_state(to_room, STATE_OLEG)
	elif to_state == STATE_FELIX:
		cams.set_camera_state(to_room, STATE_EVERY)

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
	
	real_cur = 'Eatery'
	real_prev = ''

func _on_oleg_time_timeout() -> void:
	if randf_range(1, 21) < bdifficulty:
		b()
	# В Office рассинхрон всегда выключен и не меняется.
	if real_cur == "Office":
		is_desynced = false
		return
	# Вне Office рассинхрон включается по шансу от интеллекта только один раз (false -> true).
	if not is_desynced and randf_range(bdifficulty, 101) > (bdifficulty * 5):
		is_desynced = true
		print('Рассинхронизация противника - ', is_desynced)

# Совместимость со старыми подключениями сигнала.
func _on_btimer_timeout() -> void:
	_on_oleg_time_timeout()

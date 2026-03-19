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
var eatery_calm = true
var eatery = false
var child = false
var kitchen = false
var corrid = false
var salvag = false
var way = false
var office = false
# Эти флаги пока не используются
var officeleft = false
var officeright = false
var canjumpscare = false

# Основная логика перемещения (без подготовки под лабиринт)
func b():
	if not _ensure_cams():
		return

	var from_room: String = _get_oleg_room_name_from_flags()

	if eatery_calm:
		_sync_camera_move(from_room, "Eatery")
		# После первого шага выходим из calm-режима.
		eatery_calm = false
		eatery = true
	elif eatery:
		if randf_range(1, 4) >= 2:
			_apply_room_transition("eatery_to_kitchen")
			_sync_camera_move(from_room, "Kitchen")
		else:
			_apply_room_transition("eatery_to_storage")
			_sync_camera_move(from_room, "Storage")
	elif child:
		_apply_room_transition("child_to_eatery")
		_sync_camera_move(from_room, "Eatery")
	elif kitchen:
		if randf_range(1, 4) >= 2:
			_apply_room_transition("kitchen_to_corrid")
			_sync_camera_move(from_room, "Corr")
	elif salvag:
		if randf_range(1, 4) >= 2:
			_apply_room_transition("storage_to_way")
			_sync_camera_move(from_room, "Way")
	elif corrid or way:
		if randf_range(1, 4) >= 2:
			_apply_room_transition("corrid_to_office")
			# В офисе отдельной камеры нет, поэтому Oleg уходит с текущей камеры.
			_sync_camera_move(from_room, "")
	elif office:
		_apply_room_transition("office_to_eatery")
		_sync_camera_move("", "Eatery")

# Обновляет только флаги позиций (частичный сброс сохранен).
func _apply_room_transition(transition: String) -> void:
	if transition == "eatery_to_kitchen":
		eatery = false
		kitchen = true
	elif transition == "eatery_to_storage":
		eatery = false
		salvag = true
	elif transition == "eatery_to_child":
		eatery = false
		child = true
	elif transition == "child_to_eatery":
		child = false
		eatery = true
	elif transition == "kitchen_to_eatery":
		kitchen = false
		eatery = true
	elif transition == "corrid_to_office":
		corrid = false
		office = true
	elif transition == "storage_to_kitchen":
		salvag = false
		kitchen = true
	elif transition == "office_to_eatery":
		canjumpscare = false
		office = false
		eatery = true
	elif transition == "office_ready_jumpscare":
		canjumpscare = true
		office = false
	elif transition == "kitchen_to_corrid":
		kitchen = false
		corrid = true
	elif transition == "storage_to_way":
		salvag = false
		way = true

func _get_oleg_room_name_from_flags() -> String:
	if eatery:
		return "Eatery"
	if child:
		return "Kids"
	if kitchen:
		return "Kitchen"
	if salvag:
		return "Storage"
	if corrid:
		return "Corr"
	if way:
		return "Way"
	return ""

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

func _on_oleg_time_timeout() -> void:
	# После офиса Oleg должен гарантированно выйти обратно на сцену
	# на следующем тике таймера, без дополнительной проверки difficulty.
	if office:
		b()
		return
	if randf_range(1, 20) <= bdifficulty:
		b()

# Совместимость со старыми подключениями сигнала.
func _on_btimer_timeout() -> void:
	_on_oleg_time_timeout()

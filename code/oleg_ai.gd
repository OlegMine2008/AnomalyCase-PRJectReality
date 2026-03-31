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
var current_room = 'Eatery'
var previous_room = ''
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


# # Основная логика перемещения
func b():
	pass

func _get_next_room(current_room, previous_room):
	pass

func _filter_neighbors(neighbors, previous_room):
	pass

func _choose_next_room(neighbors):
	pass

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
	if randf_range(1, 20) <= bdifficulty:
		b()

# Совместимость со старыми подключениями сигнала.
func _on_btimer_timeout() -> void:
	_on_oleg_time_timeout()

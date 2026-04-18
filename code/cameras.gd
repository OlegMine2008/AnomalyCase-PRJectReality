class_name Cameras
extends Node2D

@export var offic: Office

# Связывает имя кнопки на карте с именем спрайта камеры в Cam_Rooms.
const BUTTON_TO_FEED: Dictionary[String, String] = {
	"eatery_but": "Eatery",
	"child_but": "Kids",
	"kitchen_but": "Kitchen",
	"corrid_but": "Corr",
	"salvag_but": "Storage",
	"way_but": "Way",
	"behind_but": "Behind",
	"secret_but": "Back",
	"lab_but": "Back",
}

# Хранит пути к текстурам для каждого состояния камеры.
const CAMERAS_IMAGES: Dictionary = {
	"Eatery": {
		"Empty": "res://images/cameras/eatery/eatery.png",
		"Oleg": "res://images/cameras/eatery/eatery_o.png",
		"Felix": "res://images/cameras/eatery/eatery_f.png",
		"Every": "res://images/cameras/eatery/eatery_of.png",
	},
	"Kids": {
		"Empty": "res://images/cameras/kids/kids.png",
		"Oleg": "res://images/cameras/kids/kids_o.png",
	},
	"Kitchen": {
		"Empty": "res://images/cameras/kitchen/kitchen.png",
		"Oleg": "res://images/cameras/kitchen/kitchen_o.png",
		"Felix": "res://images/cameras/kitchen/kitchen_f.png",
	},
	"Corr": {
		"Empty": "res://images/cameras/corridor/corr.png",
		"Oleg": "res://images/cameras/corridor/corr_o.png",
		"Felix": "res://images/cameras/corridor/corr_f.png",
	},
	"Way": {
		"Empty": "res://images/cameras/corridor/corr.png",
		"Oleg": "res://images/cameras/corridor/corr_o.png",
		"Felix": "res://images/cameras/corridor/corr_f.png",
	},
	"Storage": {
		"Empty": "res://images/cameras/storage/storag.png",
		"Felix": "res://images/cameras/storage/storage_f.png",
		"Oleg": "res://images/cameras/storage/storage_o.png",
	},
	"Behind": {
		"Empty": "res://images/cameras/behind/behind.png",
		"Oleg": "res://images/cameras/behind/behind_o.png",
	},
	"Back": {
		"Empty": "res://images/cameras/background/back.png",
		"Oleg": "res://images/cameras/background/back_o.png",
	},
}

# Порядок состояний должен совпадать с индексами, которые используют AI-скрипты.
const CAMERA_STATE_KEYS: Array[String] = ["Empty", "Oleg", "Felix", "Every"]

# Быстрый доступ к спрайтам камер по имени узла.
var feeds_by_name: Dictionary[String, Sprite2D] = {}
# Быстрый доступ к кнопкам камеры по имени узла.
var buttons_by_name: Dictionary[String, TextureButton] = {}
# Текущее состояние каждой камеры по индексу из CAMERA_STATE_KEYS.
var current_camera_state: Dictionary[String, int] = {}

# Подготавливает ссылки, стартовые текстуры и начальное состояние интерфейса камер.
func _ready() -> void:
	_cache_nodes()
	_init_cameras() # Важно: сначала должны быть закешированы узлы камер.
	_connect_buttons()
	_sync_initial_button_state()
	visible = false

	var cam_sys := get_parent()
	if cam_sys != null:
		var cam_rooms := cam_sys.get_node_or_null("Cam_Rooms")
		var cam_hud := cam_sys.get_node_or_null("Cam_HUD")
		if cam_rooms is Node2D:
			(cam_rooms as Node2D).visible = false
		if cam_hud is Node2D:
			(cam_hud as Node2D).visible = false

	set_camera_state("Eatery", 3)

# Показывает или скрывает интерфейс камер в зависимости от состояния офиса.
func _process(_delta: float) -> void:
	if offic == null:
		return

	var show_cam_interface: bool = offic.cams_on and offic.cam_transition_done
	visible = show_cam_interface

	var cam_sys := get_parent()
	if cam_sys == null:
		return

	var cam_rooms := cam_sys.get_node_or_null("Cam_Rooms")
	var cam_hud := cam_sys.get_node_or_null("Cam_HUD")
	if cam_rooms is Node2D:
		(cam_rooms as Node2D).visible = show_cam_interface
	if cam_hud is Node2D:
		(cam_hud as Node2D).visible = show_cam_interface

# Собирает ссылки на спрайты камер и кнопки, чтобы не искать их каждый раз по дереву.
func _cache_nodes() -> void:
	var cam_sys := get_parent()
	if cam_sys == null:
		return

	var cam_rooms := cam_sys.get_node_or_null("Cam_Rooms")
	var cam_buttons := cam_sys.get_node_or_null("Cam_Buttons")
	if cam_rooms == null or cam_buttons == null:
		return

	for child in cam_rooms.get_children():
		if child is Sprite2D:
			feeds_by_name[child.name] = child

	for child in cam_buttons.get_children():
		if child is TextureButton:
			buttons_by_name[child.name] = child

# Подключает сигнал toggled каждой кнопки к обработчику выбора камеры.
func _connect_buttons() -> void:
	for button_name: String in BUTTON_TO_FEED.keys():
		if not buttons_by_name.has(button_name):
			continue

		var btn: TextureButton = buttons_by_name[button_name]
		var callback := Callable(self, "_on_cam_button_toggled").bind(button_name)
		if not btn.toggled.is_connected(callback):
			btn.toggled.connect(callback)

# Загружает базовые текстуры камер и сбрасывает их состояние в Empty.
func _init_cameras() -> void:
	for cam_name: String in CAMERAS_IMAGES.keys():
		current_camera_state[cam_name] = 0

		if not feeds_by_name.has(cam_name):
			continue

		var sprite: Sprite2D = feeds_by_name[cam_name]
		var path: String = _get_camera_texture_path(cam_name, 0)
		if path.is_empty():
			continue

		var texture: Texture2D = load(path)
		if texture != null:
			sprite.texture = texture
		else:
			print("Не загрузилась текстура: ", path)

# Синхронизирует стартовую видимую камеру и выбранную кнопку в ButtonGroup.
func _sync_initial_button_state() -> void:
	for button_name: String in BUTTON_TO_FEED.keys():
		if not buttons_by_name.has(button_name):
			continue
		buttons_by_name[button_name].button_pressed = false

	var visible_feed_name := _get_visible_feed_name()
	if visible_feed_name.is_empty():
		visible_feed_name = "Eatery"

	_show_only_feed(visible_feed_name)

	var button_name := _get_button_name_for_feed(visible_feed_name)
	if button_name.is_empty():
		return
	if not buttons_by_name.has(button_name):
		return

	buttons_by_name[button_name].button_pressed = true

# Реагирует только на включение кнопки и показывает соответствующую камеру.
func _on_cam_button_toggled(toggled_on: bool, button_name: String) -> void:
	if not toggled_on:
		return
	if not BUTTON_TO_FEED.has(button_name):
		return

	var feed_name: String = BUTTON_TO_FEED[button_name]
	_show_only_feed(feed_name)

# Возвращает имя первой видимой камеры, если она уже была выставлена где-то ещё.
func _get_visible_feed_name() -> String:
	for feed_name: String in feeds_by_name.keys():
		var feed: Sprite2D = feeds_by_name[feed_name]
		if feed.visible:
			return feed_name
	return ""

# Находит имя кнопки по имени камеры, чтобы синхронизировать ButtonGroup.
func _get_button_name_for_feed(feed_name: String) -> String:
	for button_name: String in BUTTON_TO_FEED.keys():
		if BUTTON_TO_FEED[button_name] == feed_name:
			return button_name
	return ""

# Скрывает все камеры и показывает только выбранную.
func _show_only_feed(feed_name: String) -> void:
	if not feeds_by_name.has(feed_name):
		return

	for f_name: String in feeds_by_name.keys():
		var f: Sprite2D = feeds_by_name[f_name]
		f.visible = false

	feeds_by_name[feed_name].visible = true

# Публичный выбор камеры по имени кнопки (без доступа к приватной логике снаружи).
func select_camera_by_button(button_name: String) -> void:
	if not BUTTON_TO_FEED.has(button_name):
		return
	if not buttons_by_name.has(button_name):
		return

	var btn: TextureButton = buttons_by_name[button_name]
	if btn.disabled or not btn.visible:
		return

	btn.button_pressed = true
	_on_cam_button_toggled(true, button_name)

# Возвращает текущую видимую камеру для внешней логики (например, режимов HUD).
func get_current_feed_name() -> String:
	return _get_visible_feed_name()

# Меняет состояние конкретной камеры и подставляет ей нужную текстуру.
func set_camera_state(cam_name: String, state_index: int) -> void:
	if not CAMERAS_IMAGES.has(cam_name):
		return

	var path: String = _get_camera_texture_path(cam_name, state_index)
	if path.is_empty():
		return

	current_camera_state[cam_name] = state_index

	if feeds_by_name.has(cam_name):
		var sprite: Sprite2D = feeds_by_name[cam_name]
		sprite.texture = load(path)

# Возвращает путь к текстуре по имени камеры и индексу состояния.
func _get_camera_texture_path(cam_name: String, state_index: int) -> String:
	if state_index < 0 or state_index >= CAMERA_STATE_KEYS.size():
		return ""
	if not CAMERAS_IMAGES.has(cam_name):
		return ""

	var state_key: String = CAMERA_STATE_KEYS[state_index]
	var states: Dictionary = CAMERAS_IMAGES[cam_name]
	if not states.has(state_key):
		return ""

	return states[state_key]

#func play_static() -> void:
#	animtree["parameters/OneShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
#	animtree.advance(0) # this fixes a problem where the static plays 1 frame too late

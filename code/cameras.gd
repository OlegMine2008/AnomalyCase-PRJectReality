class_name Cameras
extends Node2D

@export var offic: Office

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

const CAMERA_STATE_KEYS: Array[String] = ["Empty", "Oleg", "Felix", "Every"]
const AI_VISIBLE_FLASH_HOLD := 0.5

var feeds_by_name: Dictionary[String, Sprite2D] = {}
var buttons_by_name: Dictionary[String, TextureButton] = {}
var current_camera_state: Dictionary[String, int] = {}
var _pending_visible_state: Dictionary[String, int] = {}
var _pending_visible_token: Dictionary[String, int] = {}

func _ready() -> void:
	_cache_nodes()
	_init_cameras()
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

func _connect_buttons() -> void:
	for button_name: String in BUTTON_TO_FEED.keys():
		if not buttons_by_name.has(button_name):
			continue

		var btn: TextureButton = buttons_by_name[button_name]
		var callback := Callable(self, "_on_cam_button_toggled").bind(button_name)
		if not btn.toggled.is_connected(callback):
			btn.toggled.connect(callback)

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

func _on_cam_button_toggled(toggled_on: bool, button_name: String) -> void:
	if not toggled_on:
		return
	if not BUTTON_TO_FEED.has(button_name):
		return

	var feed_name: String = BUTTON_TO_FEED[button_name]
	_show_only_feed(feed_name)

func _get_visible_feed_name() -> String:
	for feed_name: String in feeds_by_name.keys():
		var feed: Sprite2D = feeds_by_name[feed_name]
		if feed.visible:
			return feed_name
	return ""

func _get_button_name_for_feed(feed_name: String) -> String:
	for button_name: String in BUTTON_TO_FEED.keys():
		if BUTTON_TO_FEED[button_name] == feed_name:
			return button_name
	return ""

func _show_only_feed(feed_name: String) -> void:
	if not feeds_by_name.has(feed_name):
		return

	for f_name: String in feeds_by_name.keys():
		var f: Sprite2D = feeds_by_name[f_name]
		f.visible = false

	feeds_by_name[feed_name].visible = true

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

func get_current_feed_name() -> String:
	return _get_visible_feed_name()

func set_camera_state(cam_name: String, state_index: int) -> void:
	if not CAMERAS_IMAGES.has(cam_name):
		return

	var path: String = _get_camera_texture_path(cam_name, state_index)
	if path.is_empty():
		return

	current_camera_state[cam_name] = state_index

	if _should_defer_visible_state_update(cam_name):
		_queue_visible_camera_state_update(cam_name, state_index)
		return

	_apply_camera_state_immediately(cam_name, state_index)

func _should_defer_visible_state_update(cam_name: String) -> bool:
	if offic == null:
		return false
	if not (offic.cams_on and offic.cam_transition_done):
		return false
	return get_current_feed_name() == cam_name

func _queue_visible_camera_state_update(cam_name: String, state_index: int) -> void:
	var token: int = int(_pending_visible_token.get(cam_name, 0)) + 1
	_pending_visible_token[cam_name] = token
	_pending_visible_state[cam_name] = state_index

	var cam_sys := get_parent()
	if cam_sys != null and cam_sys.has_method("trigger_ai_transition_flash"):
		var callback := Callable(self, "_apply_pending_visible_state").bind(cam_name, token)
		cam_sys.call("trigger_ai_transition_flash", callback, AI_VISIBLE_FLASH_HOLD)
	else:
		_apply_pending_visible_state(cam_name, token)

func _apply_pending_visible_state(cam_name: String, token: int) -> void:
	if not _pending_visible_token.has(cam_name):
		return
	if int(_pending_visible_token[cam_name]) != token:
		return
	if not _pending_visible_state.has(cam_name):
		return

	var state_index: int = int(_pending_visible_state[cam_name])
	_pending_visible_state.erase(cam_name)
	_pending_visible_token.erase(cam_name)
	_apply_camera_state_immediately(cam_name, state_index)

func _apply_camera_state_immediately(cam_name: String, state_index: int) -> void:
	var path: String = _get_camera_texture_path(cam_name, state_index)
	if path.is_empty():
		return
	if feeds_by_name.has(cam_name):
		var sprite: Sprite2D = feeds_by_name[cam_name]
		sprite.texture = load(path)

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

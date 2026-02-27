class_name Cameras
extends Node2D

@export var offic: Office

const BUTTON_TO_FEED: Dictionary[String, String] = {
	"eatery_but": "Eatery",
	"child_but": "Kids",
	"kitchen_but": "Kitchen",
	"corrid_but": "Corr",
	"salvag_but": "Storage",
	"way_but": "Corr",
	"behind_but": "Behind",
}
const CAMERAS_IMAGES: Dictionary = {
	'Eatery': {
		'Empty': 'res://images/cameras/eatery/eatery.png', 
		'Oleg': 'res://images/cameras/eatery/eatery_o.png', 
		'Felix': 'res://images/cameras/eatery/eatery_f.png', 
		'Every': 'res://images/cameras/eatery/eatery_of.png'
		},
	'Kids': {
		'Empty': 'res://images/cameras/kids/kids.png', 'Oleg':'res://images/cameras/kids/kids_o.png'
		},
	'Kitchen': {
		'Empty': 'res://images/cameras/kitchen/kitchen.png', 
		'Oleg': 'res://images/cameras/kitchen/kitchen_o.png', 
		'Felix': 'res://images/cameras/kitchen/kitchen_f.png'
	},
	'Corr': {
		'Empty': 'res://images/cameras/corridor/corr.png', 
		'Oleg': 'res://images/cameras/corridor/corr_o.png', 'Felix': 'res://images/cameras/corridor/corr_f.png'
		},
	'Storage': {'Empty': 'res://images/cameras/storage/storag.png', 'Felix': 'res://images/cameras/storage/storage_f.png', 
	'Oleg': 'res://images/cameras/storage/storage_o.png'},
	'Behind': {'Empty': 'res://images/cameras/behind/behind.png', 'Oleg': 'res://images/cameras/behind/behind_o.png'}
}
const CAMERA_STATE_KEYS: Array[String] = ["Empty", "Oleg", "Felix", "Every"]

var feeds_by_name: Dictionary[String, Sprite2D] = {}
var buttons_by_name: Dictionary[String, TextureButton] = {}
var current_camera_state: Dictionary[String, int] = {}

#@onready var animtree: AnimationTree = $AnimationTree

func _ready() -> void:
	_cache_nodes()
	_init_cameras() # ВАЖНО: после _cache_nodes()
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
	set_camera_state('Eatery', 3)

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
		if not btn.pressed.is_connected(_on_cam_button_pressed):
			btn.pressed.connect(_on_cam_button_pressed.bind(button_name))

func _init_cameras() -> void:
	for cam_name: String in CAMERAS_IMAGES.keys():
		current_camera_state[cam_name] = 0
		
		if feeds_by_name.has(cam_name):
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
	# Disable the button whose feed is currently visible (default is Eatery).
	for button_name: String in BUTTON_TO_FEED.keys():
		if not buttons_by_name.has(button_name):
			continue
		var button: TextureButton = buttons_by_name[button_name]
		button.disabled = false

	for feed_name: String in feeds_by_name.keys():
		var feed: Sprite2D = feeds_by_name[feed_name]
		if feed.visible:
			for button_name: String in BUTTON_TO_FEED.keys():
				if BUTTON_TO_FEED[button_name] == feed_name and buttons_by_name.has(button_name):
					var button: TextureButton = buttons_by_name[button_name]
					button.disabled = true

func _on_cam_button_pressed(button_name: String) -> void:
	if not BUTTON_TO_FEED.has(button_name):
		return
	var feed_name: String = BUTTON_TO_FEED[button_name]
	if not feeds_by_name.has(feed_name):
		return
	var feed: Sprite2D = feeds_by_name[feed_name]

	for f_name: String in feeds_by_name.keys():
		var f: Sprite2D = feeds_by_name[f_name]
		f.visible = false
	feed.visible = true

	for b_name: String in buttons_by_name.keys():
		var b: TextureButton = buttons_by_name[b_name]
		b.disabled = false
	if buttons_by_name.has(button_name):
		var pressed_button: TextureButton = buttons_by_name[button_name]
		pressed_button.disabled = true

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

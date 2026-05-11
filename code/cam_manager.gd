extends Node2D

@export var cams: Cameras
@export var offic: Office
@onready var text: Sprite2D = $CamMenu
@onready var static_layer: AnimatedSprite2D = $"CanvasLayer/StaticPC"
@onready var static_sound_node: Node = $static_sound

const IDLE_ALPHA := 55.0 / 255.0
const FLASH_ALPHA := 1.0
const FLASH_HOLD_TIME := 0.1
const FLASH_FADE_TIME := 0.09
const AI_FLASH_HOLD_TIME := 0.5

var _prev_show_cam_ui := false
var _static_tween: Tween = null

func _ready():
	if cams == null:
		push_error("Cam_Sys: export 'cams' is not assigned.")
		return
	if offic == null:
		push_error("Cam_Sys: export 'offic' is not assigned.")
		return
	text.visible = false
	_set_static_alpha(IDLE_ALPHA)

	var cam_buttons_root := get_node_or_null("Cam_Buttons")
	if cam_buttons_root != null:
		_connect_buttons_recursive(cam_buttons_root)
	var cam_hud_root := get_node_or_null("Cam_HUD")
	if cam_hud_root != null:
		_connect_buttons_recursive(cam_hud_root)

	_prev_show_cam_ui = offic.cams_on and offic.cam_transition_done
	_set_static_sound_active(_prev_show_cam_ui)

func _process(_delta: float):
	if cams == null or offic == null:
		return

	var show_cam_ui := offic.cams_on and offic.cam_transition_done
	text.visible = show_cam_ui
	static_layer.visible = show_cam_ui

	if show_cam_ui != _prev_show_cam_ui:
		_set_static_sound_active(show_cam_ui)

	if show_cam_ui:
		if not static_layer.is_playing():
			static_layer.play()
		if not _prev_show_cam_ui:
			_trigger_static_flash()
	else:
		if static_layer.is_playing():
			static_layer.stop()
		_stop_static_tween()
		_set_static_alpha(IDLE_ALPHA)

	_prev_show_cam_ui = show_cam_ui

func _connect_buttons_recursive(root: Node) -> void:
	for child in root.get_children():
		if child is BaseButton:
			var button := child as BaseButton
			var callback := Callable(self, "_on_cam_sys_button_pressed")
			if not button.pressed.is_connected(callback):
				button.pressed.connect(callback)
		_connect_buttons_recursive(child)

func _on_cam_sys_button_pressed() -> void:
	if offic == null:
		return
	var show_cam_ui := offic.cams_on and offic.cam_transition_done
	if not show_cam_ui:
		return
	_trigger_static_flash()

func _trigger_static_flash() -> void:
	_stop_static_tween()
	_set_static_alpha(FLASH_ALPHA)
	if static_sound_node != null and static_sound_node.has_method("trigger_sound_flash"):
		static_sound_node.call("trigger_sound_flash")

	_static_tween = create_tween()
	_static_tween.tween_interval(FLASH_HOLD_TIME)
	var fade_tween := _static_tween.tween_property(static_layer, "modulate:a", IDLE_ALPHA, FLASH_FADE_TIME)
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_OUT)

func trigger_ai_transition_flash(apply_callback: Callable, hold_time: float = AI_FLASH_HOLD_TIME) -> void:
	if offic == null:
		if apply_callback.is_valid():
			apply_callback.call()
		return

	var show_cam_ui := offic.cams_on and offic.cam_transition_done
	if not show_cam_ui:
		if apply_callback.is_valid():
			apply_callback.call()
		return

	_stop_static_tween()
	_set_static_alpha(FLASH_ALPHA)
	if static_sound_node != null and static_sound_node.has_method("trigger_sound_flash"):
		static_sound_node.call("trigger_sound_flash")

	_static_tween = create_tween()
	_static_tween.tween_interval(max(0.0, hold_time))
	if apply_callback.is_valid():
		_static_tween.tween_callback(apply_callback)
	var fade_tween := _static_tween.tween_property(static_layer, "modulate:a", IDLE_ALPHA, FLASH_FADE_TIME)
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_OUT)

func _stop_static_tween() -> void:
	if _static_tween != null and is_instance_valid(_static_tween):
		_static_tween.kill()
	_static_tween = null

func _set_static_alpha(alpha: float) -> void:
	var color := static_layer.modulate
	color.a = alpha
	static_layer.modulate = color

func _set_static_sound_active(active: bool) -> void:
	if static_sound_node == null:
		return
	if not static_sound_node.has_method("set_tablet_active"):
		push_warning("Cam_Sys: static_sound has no method set_tablet_active().")
		return
	static_sound_node.call("set_tablet_active", active)

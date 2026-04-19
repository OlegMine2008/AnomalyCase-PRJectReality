extends Node2D

@export var cams: Cameras
@export var offic: Office
@onready var text: Sprite2D = $CamMenu
@onready var static_layer: AnimatedSprite2D = $"CanvasLayer/StaticPC"
@onready var static_sound_node: Node = $static_sound

# Базовая прозрачность шума в "спокойном" состоянии: 55 из 255.
const IDLE_ALPHA := 55.0 / 255.0
# Альфа во время вспышки (полностью непрозрачно).
const FLASH_ALPHA := 1.0
# Короткая задержка перед началом плавного спада.
const FLASH_HOLD_TIME := 0.1
# Быстрый и плавный спад до IDLE_ALPHA.
const FLASH_FADE_TIME := 0.09

# Нужно, чтобы поймать момент открытия UI (переход false -> true).
var _prev_show_cam_ui := false
# Ссылка на текущий tween вспышки, чтобы можно было перезапускать эффект на частых кликах.
var _static_tween: Tween = null


# Called when the node enters the scene tree for the first time.
func _ready():
	if cams == null:
		push_error("Cam_Sys: export 'cams' is not assigned.")
		return
	if offic == null:
		push_error("Cam_Sys: export 'offic' is not assigned.")
		return
	text.visible = false
	_set_static_alpha(IDLE_ALPHA)

	# Подключаем нажатия всех кнопок внутри UI камер и HUD к одному обработчику.
	var cam_buttons_root := get_node_or_null("Cam_Buttons")
	if cam_buttons_root != null:
		_connect_buttons_recursive(cam_buttons_root)
	var cam_hud_root := get_node_or_null("Cam_HUD")
	if cam_hud_root != null:
		_connect_buttons_recursive(cam_hud_root)

	# Фиксируем стартовое состояние, чтобы вспышка срабатывала именно при открытии.
	_prev_show_cam_ui = offic.cams_on and offic.cam_transition_done
	_set_static_sound_active(_prev_show_cam_ui)


# Called every frame. 'delta' is the elapsed time since the previous frame.
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
		# Вспышка при открытии UI компьютера.
		if not _prev_show_cam_ui:
			_trigger_static_flash()
	else:
		if static_layer.is_playing():
			static_layer.stop()
		# При закрытии UI сбрасываем эффект к базовой прозрачности.
		_stop_static_tween()
		_set_static_alpha(IDLE_ALPHA)

	_prev_show_cam_ui = show_cam_ui


func _connect_buttons_recursive(root: Node) -> void:
	# Рекурсивно обходим все дочерние узлы и вешаем реакцию на нажатие кнопок.
	for child in root.get_children():
		if child is BaseButton:
			var button := child as BaseButton
			var callback := Callable(self, "_on_cam_sys_button_pressed")
			if not button.pressed.is_connected(callback):
				button.pressed.connect(callback)
		_connect_buttons_recursive(child)


func _on_cam_sys_button_pressed() -> void:
	# Эффект клика нужен только когда интерфейс камер уже открыт.
	if offic == null:
		return
	var show_cam_ui := offic.cams_on and offic.cam_transition_done
	if not show_cam_ui:
		return
	_trigger_static_flash()


func _trigger_static_flash() -> void:
	# Перезапускаем вспышку: новый клик/событие всегда начинает эффект заново.
	_stop_static_tween()
	_set_static_alpha(FLASH_ALPHA)
	if static_sound_node != null and static_sound_node.has_method("trigger_sound_flash"):
		static_sound_node.call("trigger_sound_flash")

	_static_tween = create_tween()
	_static_tween.tween_interval(FLASH_HOLD_TIME)
	var fade_tween := _static_tween.tween_property(static_layer, "modulate:a", IDLE_ALPHA, FLASH_FADE_TIME)
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_OUT)


func _stop_static_tween() -> void:
	# Если новая вспышка пришла раньше завершения старой, прерываем старый tween.
	if _static_tween != null and is_instance_valid(_static_tween):
		_static_tween.kill()
	_static_tween = null


func _set_static_alpha(alpha: float) -> void:
	# Меняем только альфу, чтобы не трогать цветовой тон статического шума.
	var color := static_layer.modulate
	color.a = alpha
	static_layer.modulate = color


func _set_static_sound_active(active: bool) -> void:
	# Основной путь: управляем звуком через скрипт static_s.gd.
	if static_sound_node == null:
		return
	if not static_sound_node.has_method("set_tablet_active"):
		push_warning("Cam_Sys: static_sound has no method set_tablet_active().")
		return
	static_sound_node.call("set_tablet_active", active)

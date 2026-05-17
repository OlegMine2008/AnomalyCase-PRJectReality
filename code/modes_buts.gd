extends Node2D

var true_vision: bool = false

var seen_mode_but: TextureButton
var true_mode_but: TextureButton
var secret_but: TextureButton
var lab_but: TextureButton
var behind_but: TextureButton
var cams: Cameras
var oleg_ai: Node
var felix_ai: Node

# Защита от зацикливания, когда мы программно меняем button_pressed.
var _mode_switch_in_progress := false

# Инициализирует ссылки на кнопки, камеры и ИИ для синхронизации режимов.
func _ready() -> void:
	# Получаем ссылки на кнопки переключения режимов сверху HUD.
	seen_mode_but = get_node_or_null("seen_mode") as TextureButton
	true_mode_but = get_node_or_null("true_mode") as TextureButton

	# Получаем ссылки на систему камер и дополнительные кнопки карт.
	var cam_sys := get_parent()
	if cam_sys != null:
		cams = cam_sys.get_node_or_null("Cam_Buttons") as Cameras
		var cam_buttons := cam_sys.get_node_or_null("Cam_Buttons")
		if cam_buttons != null:
			secret_but = cam_buttons.get_node_or_null("secret_but") as TextureButton
			lab_but = cam_buttons.get_node_or_null("lab_but") as TextureButton
			behind_but = cam_buttons.get_node_or_null("behind_but") as TextureButton

	# Ссылка на ИИ Олега, чтобы синхронизировать выбранный режим отображения.
	oleg_ai = get_node_or_null("../../Enemies/OlegTheCat")
	# Ссылка на ИИ Felix для такого же переключения vision/real режима.
	felix_ai = get_node_or_null("../../Enemies/FelixTheWolf")

	_connect_mode_buttons()

	# Стартовый режим берём из нажатой кнопки true_mode (если она выбрана в сцене).
	var start_true_mode := true_mode_but != null and true_mode_but.button_pressed
	_apply_mode(start_true_mode)


# Подключает сигналы переключателей seen/true режима.
func _connect_mode_buttons() -> void:
	# Подключаем обработчики только один раз.
	if seen_mode_but != null:
		var seen_callback := Callable(self, "_on_seen_mode_toggled")
		if not seen_mode_but.toggled.is_connected(seen_callback):
			seen_mode_but.toggled.connect(seen_callback)

	if true_mode_but != null:
		var true_callback := Callable(self, "_on_true_mode_toggled")
		if not true_mode_but.toggled.is_connected(true_callback):
			true_mode_but.toggled.connect(true_callback)


# Обрабатывает выбор seen-режима и отключает true-слой.
func _on_seen_mode_toggled(toggled_on: bool) -> void:
	if _mode_switch_in_progress or not toggled_on:
		return
	_apply_mode(false)


# Обрабатывает выбор true-режима и включает реальный слой.
func _on_true_mode_toggled(toggled_on: bool) -> void:
	if _mode_switch_in_progress or not toggled_on:
		return
	_apply_mode(true)


# Применяет режим отображения камер и синхронизирует его с ИИ.
func _apply_mode(is_true: bool) -> void:
	# Переключаем внутренний флаг режима (false = seen, true = real/true).
	true_vision = is_true

	# Скрываем/показываем кнопки секретных камер по режиму.
	_set_extra_camera_buttons_visible(true_vision)

	# Синхронизируем UI-кнопки режима в ButtonGroup.
	_mode_switch_in_progress = true
	if seen_mode_but != null:
		seen_mode_but.button_pressed = not true_vision
	if true_mode_but != null:
		true_mode_but.button_pressed = true_vision
	_mode_switch_in_progress = false

	# В seen_mode нельзя оставаться на real-only камерах, возвращаемся на Eatery.
	if not true_vision and cams != null:
		var current_feed := cams.get_current_feed_name()
		if current_feed == "Back" or current_feed == "Behind":
			cams.select_camera_by_button("eatery_but")

	# Передаём выбранный режим в Oleg AI.
	if oleg_ai != null and oleg_ai.has_method("set_true_vision"):
		oleg_ai.call("set_true_vision", true_vision)
	# Передаём выбранный режим в Felix AI.
	if felix_ai != null and felix_ai.has_method("set_true_vision"):
		felix_ai.call("set_true_vision", true_vision)


# Переключает видимость дополнительных кнопок true-режима.
func _set_extra_camera_buttons_visible(visible_state: bool) -> void:
	# Камеры, доступные только в true-режиме.
	_set_button_state(secret_but, visible_state)
	_set_button_state(lab_but, visible_state)
	_set_button_state(behind_but, visible_state)


# Применяет состояние одной кнопки и очищает pressed при скрытии.
func _set_button_state(button: TextureButton, visible_state: bool) -> void:
	if button == null:
		return

	# При скрытии кнопки обязательно выключаем её "нажатость",
	# чтобы не оставлять UI в невалидном состоянии.
	button.visible = visible_state
	button.disabled = not visible_state
	if not visible_state:
		button.button_pressed = false

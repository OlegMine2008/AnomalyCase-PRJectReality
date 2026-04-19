extends AudioStreamPlayer

# Базовый тон (нормальный)
const IDLE_PITCH := 1.0
# Во время "вспышки" тон тоже не меняем, чтобы не было писка.
const FLASH_PITCH := 1.0

# Короткая задержка перед спадом
const FLASH_HOLD_TIME := 0.1
# Время возврата к норме
const FLASH_FADE_TIME := 0.09

var _audio_tween: Tween = null
# Флаг, открыт ли сейчас планшет/интерфейс камер.
var _tablet_open := false
# Базовые значения звука по задаче: громкость 2 dB и тон 1.0.
const IDLE_VOLUME_DB := 2.0
# Вспышка делается по громкости, но без изменения тона.
# Держим запас по уровню, чтобы избежать клиппинга/искажений.
const FLASH_VOLUME_DB := 4.5


func _ready():
	# База задаётся жёстко и больше нигде не перерассчитывается.
	pitch_scale = IDLE_PITCH
	volume_db = IDLE_VOLUME_DB
	stop()


func set_tablet_active(is_open: bool) -> void:
	# Если состояние не изменилось, но планшет открыт и звук почему-то встал,
	# поднимаем воспроизведение в базовых параметрах.
	if _tablet_open == is_open:
		if _tablet_open and not playing:
			_stop_audio_tween()
			pitch_scale = IDLE_PITCH
			volume_db = IDLE_VOLUME_DB
			play()
		return

	_tablet_open = is_open
	if _tablet_open:
		# При каждом открытии планшета гарантируем базовый тон/громкость.
		_stop_audio_tween()
		pitch_scale = IDLE_PITCH
		volume_db = IDLE_VOLUME_DB
		if not playing:
			play()
	else:
		_stop_audio_tween()
		pitch_scale = IDLE_PITCH
		volume_db = IDLE_VOLUME_DB
		if playing:
			stop()


func trigger_sound_flash() -> void:
	# Эффект вспышки звука разрешён только при открытом планшете.
	if not _tablet_open:
		return

	# Если по какой-то причине плеер остановился, поднимаем его заново.
	if not playing:
		pitch_scale = IDLE_PITCH
		volume_db = IDLE_VOLUME_DB
		play()

	# Перезапуск эффекта как у тебя с визуалом
	_stop_audio_tween()

	# Тон остаётся 1.0, вспышка идёт только через краткий буст громкости.
	pitch_scale = FLASH_PITCH
	volume_db = FLASH_VOLUME_DB

	_audio_tween = create_tween()
	_audio_tween.tween_interval(FLASH_HOLD_TIME)

	var pitch_tween = _audio_tween.tween_property(self, "pitch_scale", IDLE_PITCH, FLASH_FADE_TIME)
	pitch_tween.set_trans(Tween.TRANS_SINE)
	pitch_tween.set_ease(Tween.EASE_OUT)

	var volume_tween = _audio_tween.parallel().tween_property(self, "volume_db", IDLE_VOLUME_DB, FLASH_FADE_TIME)
	volume_tween.set_trans(Tween.TRANS_SINE)
	volume_tween.set_ease(Tween.EASE_OUT)


func _stop_audio_tween() -> void:
	if _audio_tween != null and is_instance_valid(_audio_tween):
		_audio_tween.kill()
	_audio_tween = null

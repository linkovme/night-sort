class_name SynthSfx
extends Node

const SAMPLE_RATE := 22050

func play_switch() -> void:
	_play_tone(280.0, 0.035, 0.16)

func play_correct(combo: int) -> void:
	var pitch := 470.0 + minf(float(combo), 20.0) * 11.0
	_play_tone(pitch, 0.075, 0.20)

func play_wrong() -> void:
	_play_tone(165.0, 0.13, 0.24)

func play_upgrade() -> void:
	_play_tone(620.0, 0.10, 0.20)
	_play_tone(820.0, 0.07, 0.13, 0.055)

func play_complete(success: bool) -> void:
	if success:
		_play_tone(520.0, 0.12, 0.18)
		_play_tone(690.0, 0.15, 0.18, 0.09)
	else:
		_play_tone(145.0, 0.20, 0.22)

func _play_tone(
	frequency: float,
	duration: float,
	volume: float,
	delay: float = 0.0
) -> void:
	if delay > 0.0:
		var timer := get_tree().create_timer(delay)
		await timer.timeout
	if not is_inside_tree():
		return

	var stream := _make_tone(frequency, duration, volume)
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _make_tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_count := maxi(1, int(float(SAMPLE_RATE) * duration))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)

	for i in range(sample_count):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := float(i) / float(sample_count)
		var envelope := 1.0 - progress
		envelope *= envelope
		var wave := sin(TAU * frequency * t)
		var sample := int(clampf(wave * envelope * volume, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	return wav

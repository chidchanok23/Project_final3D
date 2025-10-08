extends Node

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	bgm_player.autoplay = false
	bgm_player.volume_db = -6

	if AudioServer.get_bus_index("Music") != -1:
		bgm_player.bus = "Music"
	else:
		bgm_player.bus = "Master"

	if AudioServer.get_bus_index("SFX") != -1:
		sfx_player.bus = "SFX"
	else:
		sfx_player.bus = "Master"


func play_bgm(bgm_stream: AudioStream) -> void:
	if bgm_stream:
		bgm_player.stream = bgm_stream
		bgm_player.play()


func stop_bgm() -> void:
	if bgm_player.playing:
		bgm_player.stop()


func play_sfx(sfx_stream: AudioStream) -> void:
	if sfx_stream:
		sfx_player.stream = sfx_stream
		sfx_player.play()


# 🟢 เพิ่มฟังก์ชันนี้เพื่อปรับความดังเสียง
func set_volume(normalized_value: float) -> void:
	# normalized_value ควรอยู่ในช่วง 0.0 - 1.0
	# แปลงเป็น dB (จาก -80 dB ถึง 0 dB)
	var volume_db = lerp(-80.0, 0.0, normalized_value)
	bgm_player.volume_db = volume_db
	sfx_player.volume_db = volume_db

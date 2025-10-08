extends Control


func _on_volume_value_changed(value: float) -> void:
	var normalized = value / 100.0   # แปลงเป็น 0.0 - 1.0
	AudioManager.set_volume(normalized)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_packed(load("res://menu/menu.tscn"))


func _on_mute_toggled(toggled_on: bool) -> void:
	if toggled_on:
		# กด mute → ลดเสียงเป็น -80dB (เงียบสุด)
		AudioManager.set_volume(0)
	else:
		# ปิด mute → กลับไปเสียงปกติ 0dB
		AudioManager.set_volume(-80)

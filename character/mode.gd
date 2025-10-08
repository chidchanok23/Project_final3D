extends Control

# ปุ่ม 3 ปุ่มใน UI
@onready var easy_btn: Button = $easy
@onready var normal_btn: Button = $normal
@onready var hard_btn: Button = $hard
@onready var dlc: Control = $dlc

func _ready() -> void:
	dlc.visible = false
	if not easy_btn.pressed.is_connected(_on_easy_pressed):
		easy_btn.pressed.connect(_on_easy_pressed)
	if not normal_btn.pressed.is_connected(_on_normal_pressed):
		normal_btn.pressed.connect(_on_normal_pressed)
	if not hard_btn.pressed.is_connected(_on_hard_pressed):
		hard_btn.pressed.connect(_on_hard_pressed)

func _on_easy_pressed() -> void:
	dlc.visible = true
	await get_tree().create_timer(3.0).timeout
	dlc.visible = false

func _on_normal_pressed() -> void:
	Global.difficulty = "normal"
	print("Difficulty set to NORMAL")
	_load_game_scene()

func _on_hard_pressed() -> void:
	dlc.visible = true
	await get_tree().create_timer(3.0).timeout
	dlc.visible = false

func _load_game_scene() -> void:
	# โหลดฉาก test.tscn
	get_tree().change_scene_to_file("res://world/assets/world.tscn")

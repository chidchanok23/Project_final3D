extends Node3D

# node ของศัตรูใน scene
@onready var man: Node = $man
@onready var ratri: Node = $ratri
@onready var student: Node = $student

var all_keys: Array[Node3D] = []
var all_holy: Array[Node3D] = []

func _ready() -> void:
	# --- ดึง Key ทั้งหมด 20 อัน ---
	for i in range(1, 21):
		var key_node = get_node_or_null("key%d" % i)
		if key_node:
			all_keys.append(key_node)

	# --- ดึง Holy ทั้งหมด 5 อัน ---
	for i in range(1, 6):
		var holy_node = get_node_or_null("holy%d" % i)
		if holy_node:
			all_holy.append(holy_node)

	# --- คำนวณจำนวนที่จะสุ่มตามระดับความยาก ---
	var num_keys := 0
	match Global.difficulty:
		"easy": num_keys = 5
		"normal": num_keys = 7
		"hard": num_keys = 9
		_: num_keys = 5

	# --- สุ่ม Key และ Holy ---
	all_keys.shuffle()
	all_holy.shuffle()
	var random_keys = all_keys.slice(0, num_keys)
	var random_holy = all_holy.slice(0, 3)

	# --- ซ่อนทั้งหมดก่อน ---
	for key in all_keys:
		key.visible = false
		var area = key.get_node_or_null("Area3D")
		if area:
			area.monitoring = false
			area.visible = false

	for holy in all_holy:
		holy.visible = false
		var area = holy.get_node_or_null("Area3D")
		if area:
			area.monitoring = false
			area.visible = false

	# --- แสดงเฉพาะที่สุ่มได้ ---
	for key in random_keys:
		key.visible = true
		var area = key.get_node_or_null("Area3D")
		if area:
			area.monitoring = true
			area.visible = true

	for holy in random_holy:
		holy.visible = true
		var area = holy.get_node_or_null("Area3D")
		if area:
			area.monitoring = true
			area.visible = true

	# --- เล่นเพลง BGM ของ world ---
	AudioManager.play_bgm(load("res://world/world_bg_sound.mp3"))

	# --- แสดงเฉพาะศัตรูตามระดับความยาก ---
	match Global.difficulty:
		"easy":
			_activate_enemy(man)
			_deactivate_enemy(ratri)
			_deactivate_enemy(student)
		"normal":
			_activate_enemy(ratri)
			_deactivate_enemy(man)
			_deactivate_enemy(student)
		"hard":
			_activate_enemy(student)
			_deactivate_enemy(man)
			_deactivate_enemy(ratri)

# ---------------------------
# ฟังก์ชันเปิดการทำงานศัตรู
# ---------------------------
func _activate_enemy(enemy: Node) -> void:
	if enemy:
		enemy.visible = true
		enemy.set_physics_process(true)
		enemy.set_process(true)

# ---------------------------
# ฟังก์ชันปิดการทำงานศัตรู
# ---------------------------
func _deactivate_enemy(enemy: Node) -> void:
	if enemy:
		enemy.visible = false
		enemy.set_physics_process(false)
		enemy.set_process(false)

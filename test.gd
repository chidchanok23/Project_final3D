extends Node

@onready var man = $GhostPath/PathFollow3D/man
@onready var ratri = $GhostPath/PathFollow3D/ratri
@onready var student = $GhostPath/PathFollow3D/student
@onready var player: Node = $Player
@onready var keys: Array = [$Key1] # ใส่ key ทั้งหมดที่ scene

func _ready() -> void:
	for key in keys:
		key.connect("player_entered", player, "_on_key_area_body_entered")
		key.connect("player_exited", player, "_on_key_area_body_exited")
	# เปิด ghost ตาม difficulty
	match Global.difficulty:
		"easy":
			_set_active_enemy(man)
		"normal":
			_set_active_enemy(ratri)
		"hard":
			_set_active_enemy(student)

func _set_active_enemy(active_enemy: Node3D) -> void:
	# ปิด ghost ตัวอื่นทั้งหมด
	man.visible = false
	ratri.visible = false
	student.visible = false

	active_enemy.visible = true
	print("%s is active" % active_enemy.name)

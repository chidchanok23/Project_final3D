extends Node3D

# --- Nodes / References ---
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var area: Area3D = $Area3D
@onready var ui_open: Control = $open_door
@onready var ui_close: Control = $close_door
@onready var audio_open: AudioStreamPlayer = $door_open
@onready var audio_close: AudioStreamPlayer = $door_close

# --- State ---
var player_in_range: bool = false
var door_state: String = "close"   # เริ่มจากปิด

func _ready() -> void:
	anim.play("RESET")  # ประตูเริ่มที่ปิด
	ui_open.visible = false
	ui_close.visible = false

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		if door_state == "close":
			_open_door()
		elif door_state == "open":
			_close_door()

# -----------------------------
# OPEN / CLOSE DOOR
# -----------------------------
func _open_door() -> void:
	print("Opening door...")
	
	# เล่นเสียง open
	audio_open.play()
	
	# เล่นอนิเมชั่น
	anim.play("door_open")
	door_state = "open"
	
	# ซ่อน UI ระหว่างอนิเมชั่น
	ui_open.visible = false
	ui_close.visible = false

func _close_door() -> void:
	print("Closing door...")
	
	# เล่นเสียง close
	audio_close.play()
	
	# เล่นอนิเมชั่น
	anim.play("door_close")
	door_state = "close"
	
	# ซ่อน UI ระหว่างอนิเมชั่น
	ui_open.visible = false
	ui_close.visible = false

# -----------------------------
# AREA DETECTION
# -----------------------------
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		# แสดง UI ตามสถานะ
		if door_state == "close":
			ui_open.visible = true
			ui_close.visible = false
		elif door_state == "open":
			ui_open.visible = false
			ui_close.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		ui_open.visible = false
		ui_close.visible = false

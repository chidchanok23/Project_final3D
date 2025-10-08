extends CharacterBody3D

# --- Movement Settings ---
@export var speed: float = 6.0
@export var sprint_speed: float = 10.0

# --- Camera / Mouse Settings ---
@export var mouse_sensitivity: float = 0.003
var pitch: float = 0.0   # กล้องก้ม/เงย

# --- References ---
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var anim_player: AnimationPlayer = $Player/AnimationPlayer

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# หมุนซ้าย-ขวา
		rotation.y -= event.relative.x * mouse_sensitivity
		
		# หมุนกล้องขึ้น-ลง (จำกัดองศาไว้ -30 ถึง +30 องศา)
		pitch = clamp(pitch + event.relative.y * mouse_sensitivity, -PI/14, PI/6)
		head.rotation.x = pitch

func _physics_process(delta: float) -> void:
	var velocity: Vector3 = Vector3.ZERO

	# --- Movement Input ---
	var input_dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.z += 1
	if Input.is_action_pressed("move_back"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_left"):
		input_dir.x += 1
	if Input.is_action_pressed("move_right"):
		input_dir.x -= 1
	
	input_dir = input_dir.normalized()
	
	# --- Choose speed ---
	var current_speed = speed
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed

	# --- Apply direction relative to player ---
	var direction = (transform.basis * input_dir).normalized()
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	# --- Apply movement ---
	self.velocity = velocity
	move_and_slide()

	# --- Play animation ---
	_update_animation(velocity)

# -----------------------------
func _update_animation(velocity: Vector3) -> void:
	var horizontal_speed = Vector3(velocity.x, 0, velocity.z).length()
	
	if horizontal_speed < 0.01:
		# ยืนอยู่กับที่
		if anim_player.current_animation != "Animation/idle":
			anim_player.play("Animation/idle")
	elif horizontal_speed < speed + 0.01:
		# เดิน
		if anim_player.current_animation != "Animation/walking":
			anim_player.play("Animation/walking")
	else:
		# วิ่ง
		if anim_player.current_animation != "Animation/running":
			anim_player.play("Animation/running")

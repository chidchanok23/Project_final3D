extends CharacterBody3D

@export var speed = 14
@export var fall_acceleration = 75

@export var bounce_impulse = 16
@export var mouse_sensitivity = 0.003

var target_velocity = Vector3.ZERO
signal hit

var pitch := 0.0  # สำหรับเงย/ก้ม

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # ซ่อนเมาส์

func _input(event):
	if event is InputEventMouseMotion:
		# หมุนซ้าย-ขวา
		rotation.y -= event.relative.x * mouse_sensitivity
		
		# หมุนกล้องขึ้น-ลง (จำกัดองศาไว้ -90 ถึง 90)
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -PI/2, PI/2)
		$Pivot.rotation.x = pitch

func _physics_process(delta):
	var direction = Vector3.ZERO

	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1

	if direction != Vector3.ZERO:
		direction = (transform.basis * direction).normalized()

	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Gravity
	if not is_on_floor():
		velocity.y -= fall_acceleration * delta
	else:
		velocity.y = 0

	# Jump


	# Apply horizontal velocity
	velocity.x = target_velocity.x
	velocity.z = target_velocity.z
	
	move_and_slide()

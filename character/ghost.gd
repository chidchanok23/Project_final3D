extends CharacterBody3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var blood: Control = $Blood

# --------------------
# CONFIG
# --------------------
@export var patrol_points: Array[Node3D] = []
@export var speed_walk: float = 0.5
@export var speed_run: float = 2.0
@export var attack_range: float = 2.0
@export var chase_range: float = 10.0
@export var investigate_wait_time: float = 4.0
@export var patrol_wait_time: float = 3.0
@export var update_interval: float = 0.2

const SMOOTHING_FACTOR = 0.2
const ROTATION_LERP = 0.12

# --------------------
# STATE MACHINE
# --------------------
enum State { IDLE, PATROL, INVESTIGATE, CHASE, ATTACK, RETURN }
var state: State = State.IDLE
var patrol_index := 0
var patrol_timer := 0.0
var investigate_timer := 0.0
var investigate_position: Vector3
var return_position: Vector3
var target: Node3D
var update_timer := 0.0
var attack = false
var active_in_mode := true   # <<< ถ้า false ผีจะไม่เดิน/โจมตี

# --------------------
# READY
# --------------------
func _ready() -> void:
	blood.visible = false

	# รอ 2 วินาที ให้ Player กำหนดตัวเองลง PlayerManager.player
	await get_tree().create_timer(2.0).timeout

	target = PlayerManager.player
	if target == null:
		print("⚠️ PlayerManager.player is still null! Ghost ยังหา Player ไม่เจอ")

	_enter_state(State.IDLE if patrol_points.is_empty() else State.PATROL)


# --------------------
# MAIN LOOP
# --------------------
func _physics_process(delta: float) -> void:
	if not active_in_mode:
		return   # ผีตัวนี้ไม่ active จะไม่ทำงาน

	update_timer -= delta
	if update_timer <= 0.0:
		_update_agent_target()
		update_timer = update_interval

	match state:
		State.IDLE:        _state_idle()
		State.PATROL:      _state_patrol(delta)
		State.INVESTIGATE: _state_investigate(delta)
		State.CHASE:       _state_chase(delta)
		State.ATTACK:      _state_attack()
		State.RETURN:      _state_return(delta)
	
	move_and_slide()

# --------------------
# STATE HANDLERS
# --------------------
func _state_idle() -> void:
	if _is_player_in_chase_range():
		_enter_state(State.CHASE)

func _state_patrol(delta: float) -> void:
	if agent.is_navigation_finished():
		if patrol_timer <= 0.0:
			patrol_timer = patrol_wait_time
			_stop_and_idle()
		else:
			patrol_timer -= delta
			if patrol_timer <= 0.0:
				_go_to_next_patrol_point()
	else:
		_walk_to(agent.get_next_path_position(), speed_walk)

	if _is_player_in_chase_range():
		_enter_state(State.CHASE)

func _state_investigate(delta: float) -> void:
	if agent.is_navigation_finished():
		if investigate_timer <= 0.0:
			investigate_timer = investigate_wait_time
			_stop_and_idle()
		else:
			investigate_timer -= delta
			if investigate_timer <= 0.0:
				_enter_state(State.RETURN)
	else:
		_walk_to(agent.get_next_path_position(), speed_walk)

	if _is_player_in_chase_range():
		_enter_state(State.CHASE)

func _state_chase(delta: float) -> void:
	if target == null:
		_enter_state(State.RETURN)
		return
	$Sound.play()
	_walk_to(target.global_transform.origin, speed_run)

	if global_transform.origin.distance_to(target.global_transform.origin) < attack_range:
		_enter_state(State.ATTACK)

func _state_attack() -> void:
	velocity = Vector3.ZERO

	if anim.has_animation("Animation/zombie_attack_(1)") and attack == false:
		anim.play("Animation/zombie_attack_(1)")
		# ตรวจสอบ player ก่อนเรียก die()
		if PlayerManager.player != null:
			PlayerManager.player.die()
		await anim.animation_finished
		attack = true
	elif attack:
		anim.play("Animation/zombie_idle")

func _state_return(delta: float) -> void:
	if agent.is_navigation_finished():
		_enter_state(State.PATROL)
	else:
		_walk_to(agent.get_next_path_position(), speed_walk)

# --------------------
# HELPERS
# --------------------
func _enter_state(new_state: State) -> void:
	state = new_state
	match state:
		State.PATROL:
			patrol_timer = 0
			_go_to_next_patrol_point()
		State.INVESTIGATE:
			investigate_timer = 0.0
			agent.set_target_position(investigate_position)
		State.CHASE:
			return_position = global_transform.origin

func _update_agent_target() -> void:
	match state:
		State.PATROL:
			if patrol_points.size() > 0:
				agent.set_target_position(patrol_points[patrol_index].global_transform.origin)
		State.INVESTIGATE:
			agent.set_target_position(investigate_position)
		State.CHASE:
			if target:
				agent.set_target_position(target.global_transform.origin)
		State.RETURN:
			agent.set_target_position(return_position)

func _walk_to(next_pos: Vector3, speed: float) -> void:
	if speed >= speed_run:
		anim.play("Animation/zombie_running")
	else:
		anim.play("Animation/zombie_walk_(6)")
	_move_towards(next_pos, speed)

func _stop_and_idle() -> void:
	velocity = Vector3.ZERO
	anim.play("Animation/zombie_idle")

func _go_to_next_patrol_point() -> void:
	patrol_index = (patrol_index + 1) % patrol_points.size()
	agent.set_target_position(patrol_points[patrol_index].global_transform.origin)

# --------------------
# CORE MOVEMENT
# --------------------
func _move_towards(next_pos: Vector3, speed: float) -> void:
	var dir = (next_pos - global_transform.origin)
	dir.y = 0.0
	if is_zero_approx(dir.length()):
		velocity.x = lerp(velocity.x, 0.0, SMOOTHING_FACTOR)
		velocity.z = lerp(velocity.z, 0.0, SMOOTHING_FACTOR)
		return

	dir = dir.normalized()
	var look_target = global_transform.origin + dir
	look_at(look_target, Vector3.UP)
	rotate_y(deg_to_rad(180))
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

# --------------------
# PLAYER DETECTION
# --------------------
func _is_player_in_chase_range() -> bool:
	if target == null:
		return false
	var distance = global_transform.origin.distance_to(target.global_transform.origin)
	return distance <= chase_range

func hear_noise(pos: Vector3) -> void:
	if state not in [State.CHASE, State.ATTACK]:
		investigate_position = pos
		_enter_state(State.INVESTIGATE)

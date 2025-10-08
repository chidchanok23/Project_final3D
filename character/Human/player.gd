extends CharacterBody3D
signal hide_world_ui
# --- Movement Settings ---
@export var speed: float = 3.0
@export var sprint_speed: float = 6.0

# --- Camera / Mouse Settings ---
@export var mouse_sensitivity: float = 0.003
var pitch: float = 0.0   # กล้องก้ม/เงย
var holy_count: int = 0
var key_count: int = 0
var switching: bool = false 

# --- References ---
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var gameover_anim: Control = $CanvasLayer/gameover
@onready var ratri_camera: Camera3D = null

# --- Pick UI System ---
@onready var complete: Control = $CanvasLayer/Complete
@onready var world_ui: Control = $CanvasLayer/world_ui
@onready var pick_ui: Control = $CanvasLayer/Pick_key
@onready var key_label: Label = $CanvasLayer/world_ui/KeyLabel
@onready var holy_label: Label = $CanvasLayer/world_ui/HolyWaterLabel
@onready var key_icon: TextureRect = $CanvasLayer/world_ui/KeyIcon
@onready var holy_icon: TextureRect = $CanvasLayer/world_ui/HolyWaterIcon
@onready var pick_sound: AudioStreamPlayer = $Pick
@onready var esc_menu: Control = $CanvasLayer/esc
var esc_visible: bool = false
var current_interactable: Node3D = null

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("switch_cam"):
		_try_switch_camera()

func _ready() -> void:
	complete.visible = false
	hide_world_ui.connect(_on_hide_world_ui)
	PlayerManager.player = self
	var cameras = get_tree().get_nodes_in_group("RatriCamera")
	if cameras.size() > 0:
		ratri_camera = cameras[0]
		
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	esc_menu.connect("return_pressed", Callable(self, "_hide_esc_menu"))
	var esc_visible: bool = false
	# --- ซ่อน UI ตอนเริ่ม ---
	pick_ui.visible = false

	# --- เชื่อมสัญญาณจาก key และ holy ---
	var world = get_tree().get_current_scene()
	for node in world.get_children():
		# ✅ ตรวจชื่อแบบไม่สนตัวพิมพ์เล็กใหญ่
		if node.name.to_lower().begins_with("key") or node.name.to_lower().begins_with("holy"):
			if node.has_signal("player_entered"):
				node.player_entered.connect(_on_item_entered)
			if node.has_signal("player_exited"):
				node.player_exited.connect(_on_item_exited)

	# ✅ Debug ตรวจสอบว่าเจอ UI หรือไม่
	if pick_ui == null:
		push_warning("⚠️ Pick_key UI not found! ตรวจ path ให้ถูกต้อง เช่น $CanvasLayer/Pick_key")


func _on_hide_world_ui():
	world_ui.visible = false
	complete.visible = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		print("DEBUG: interact pressed! current_interactable =", current_interactable)

	if not esc_visible and event is InputEventMouseMotion:
		# หมุนซ้าย-ขวา
		rotation.y -= event.relative.x * mouse_sensitivity
		# หมุนกล้องขึ้น-ลง (จำกัดองศาไว้ -30 ถึง +30 องศา)
		pitch = clamp(pitch + event.relative.y * mouse_sensitivity, -PI/14, PI/6)
		head.rotation.x = pitch
		
	if event.is_action_pressed("interact") and current_interactable != null:
		# ตรวจสอบ group ก่อนเก็บ
		if current_interactable.is_in_group("Key"):
			print("DEBUG: Pressed interact on KEY:", current_interactable.name)
			_pick_up_key(current_interactable)
		elif current_interactable.is_in_group("HolyWater"):
			print("DEBUG: Pressed interact on HOLY WATER:", current_interactable.name)
			_pick_up_holy(current_interactable)
		else:
			print("DEBUG: Pressed interact on unknown item:", current_interactable.name)
			
	if event.is_action_pressed("ui_cancel"):  # ปุ่ม ESC
		_toggle_esc_menu()

	if event.is_action_pressed("ui_accept"):  # ปุ่ม Enter / Return
		if esc_visible:
			_hide_esc_menu()
			
func _try_switch_camera() -> void:
	if switching:
		return

	if holy_count > 0 and is_instance_valid(ratri_camera):
		key_icon.visible = false
		holy_icon.visible = false
		key_label.visible = false
		holy_label.visible = false
		switching = true
		holy_count -= 1
		print("🔮 Switching to Ratri cam, holy left:", holy_count)
		if holy_label:
			holy_label.text = str(holy_count)

		# ปิด player cam แล้วเปิด ratri cam
		camera.current = false
		ratri_camera.current = true

		await get_tree().create_timer(5.0).timeout

		# กลับมาที่ player cam
		if is_instance_valid(camera):
			camera.current = true
			key_label.visible = true
			holy_label.visible = true
			key_icon.visible = true
			holy_icon.visible = true
		if is_instance_valid(ratri_camera):
			ratri_camera.current = false

		switching = false
		print("🎥 Switched back to Player cam")
	else:
		print("⚠️ Cannot switch camera — no holy left or Ratri camera not found.")
			
func _toggle_esc_menu() -> void:
	esc_visible = !esc_visible
	esc_menu.visible = esc_visible
	
	if esc_visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _hide_esc_menu() -> void:
	esc_visible = false
	$CanvasLayer/esc.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# --- สำคัญ: เก็บค่าแนวดิ่ง (y) ไว้ก่อน เพราะถ้ารีเซ็ตเป็น 0 ทุกเฟรม
	#            อาจทำให้การชน/แรงโน้มถ่วงเพี้ยนหรือทะลุวัตถุได้ ---
	var vy: float = self.velocity.y

	# --- Movement Input ---
	var input_dir := Vector3.ZERO
	if Input.is_action_pressed("up"):
		input_dir.z += 1
	if Input.is_action_pressed("down"):
		input_dir.z -= 1
	if Input.is_action_pressed("left"):
		input_dir.x += 1
	if Input.is_action_pressed("right"):
		input_dir.x -= 1
	
	input_dir = input_dir.normalized()
	
	# --- Choose speed ---
	var current_speed = speed
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed

	# --- Apply direction relative to player ---
	var direction = (transform.basis * input_dir)
	if direction.length() > 0.0:
		direction = direction.normalized()
	
	# --- ตั้งความเร็วเฉพาะแกน X,Z โดยไม่แตะ Y (vy ถูกเก็บไว้ด้านบน) ---
	self.velocity.x = direction.x * current_speed
	self.velocity.z = direction.z * current_speed
	self.velocity.y = vy

	# --- Move using CharacterBody3D's velocity (Godot 4 move_and_slide() ใช้ velocity ของ node) ---
	move_and_slide()

	# --- Play animation (ยังใช้ค่า velocity ของ node ได้ตามเดิม) ---
	_update_animation(self.velocity)

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
	
func die() -> void:
	# --- หยุดการควบคุม player ---
	set_physics_process(false)
	set_process_input(false)

	# --- เล่น animation ตาย ---
	if anim_player.has_animation("Animation/dying_backwards"):
		anim_player.play("Animation/dying_backwards")
		await anim_player.animation_finished
		AudioManager.stop_bgm()
		gameover_anim.fade()

	# --- หลัง animation ตายจบ อาจทำอะไรเพิ่มเติมได้ เช่น ซ่อน player ---
	# visible = false  # ถ้าต้องการซ่อนตัว player หลังตาย

# -----------------------------
# ✅ ฟังก์ชันแสดง/ซ่อน Pick_key UI
func _on_item_entered(item: Node3D) -> void:
	print("DEBUG: show Pick_key for", item.name)
	pick_ui.visible = true
	current_interactable = item
	print("DEBUG: current_interactable set to", current_interactable)


func _on_item_exited(item: Node3D) -> void:
	if current_interactable == item:
		print("DEBUG: hide Pick_key for", item.name)
		pick_ui.visible = false
		current_interactable = null
		
# -----------------------------
func _update_key_ui() -> void:
	if key_label:
		key_label.text = str(key_count) + "/7"
	else:
		push_warning("⚠️ key label not found, ตรวจ path ที่ $CanvasLayer/Holy_UI/Label")
		
func _pick_up_key(item: Node3D) -> void:
	print("✅ Picked up KEY:", item.name)
	pick_ui.visible = false
	current_interactable = null
	key_count += 1
	pick_sound.play()
	_update_key_ui()
	item.queue_free()

func _update_holy_ui() -> void:
	if holy_label:
		holy_label.text = str(holy_count)
	else:
		push_warning("⚠️ Holy label not found, ตรวจ path ที่ $CanvasLayer/Holy_UI/Label")
		
func _pick_up_holy(item: Node3D) -> void:
	print("✅ Picked up HOLY WATER:", item.name)
	pick_ui.visible = false
	current_interactable = null
	holy_count += 1
	pick_sound.play()
	_update_holy_ui()
	item.queue_free()

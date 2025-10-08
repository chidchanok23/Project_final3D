extends Node3D

@onready var interact_ui: Control = $Interact
@onready var hide_ui: Control = $Hide
@onready var area: Area3D = $Area3D
@onready var wardrobe_sound: AudioStreamPlayer = $Sound  # <- ตัวเล่นเสียง

@export var hide_position: Node3D
@export var exit_position: Node3D

var player: Node = null
var player_in_range: bool = false
var is_hidden: bool = false

func _ready() -> void:
	print("Wardrobe ready")
	interact_ui.visible = false
	hide_ui.visible = false

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		# เล่นเสียงทุกครั้งที่ interact
		if wardrobe_sound:
			wardrobe_sound.play()

		if not is_hidden:
			_enter_hide()
		else:
			_exit_hide()

func _enter_hide() -> void:
	if player and hide_position:
		player.global_transform.origin = hide_position.global_transform.origin
		var rot = player.rotation
		rot.y += PI
		player.rotation = rot

		hide_ui.visible = true
		player.set_physics_process(false)
		player.set_process_input(false)
		is_hidden = true
		print("Player is now hidden")

func _exit_hide() -> void:
	if player and exit_position:
		player.global_transform.origin = exit_position.global_transform.origin
		var rot = player.rotation
		rot.y += PI
		player.rotation = rot

		hide_ui.visible = false
		player.set_physics_process(true)
		player.set_process_input(true)
		is_hidden = false
		print("Player exited hiding")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		player = body
		interact_ui.visible = true
		print("Player entered wardrobe area")

func _on_body_exited(body: Node) -> void:
	if body == player:
		player_in_range = false
		player = null
		interact_ui.visible = false
		print("Player exited wardrobe area")

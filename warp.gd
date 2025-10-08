extends Node3D

@onready var area: Area3D = $Area3D
@onready var complete_ui: Control = $Complete

func _ready():
	complete_ui.visible = false
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		complete_ui.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		print("Player entered warp area: show complete")

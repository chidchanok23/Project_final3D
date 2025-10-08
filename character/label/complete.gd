extends Control

@export var menu: PackedScene

func _ready() -> void:
	$Back.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	if menu:
		get_tree().change_scene_to_packed(menu)

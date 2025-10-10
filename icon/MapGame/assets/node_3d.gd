extends Node3D

@onready var cam: Camera3D = $Screenshot

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	take_screenshot()

func take_screenshot():
	var img: Image = get_viewport().get_texture().get_image()
	var save_path = "/Users/booboo/Documents/menu.png"
	
	var err = img.save_png(save_path)
	if err == OK:
		print("📸 Screenshot saved to: ", save_path)
	else:
		print("❌ Failed to save screenshot, error code: ", err)

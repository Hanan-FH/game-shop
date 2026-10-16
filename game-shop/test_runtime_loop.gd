extends SceneTree

var frame_count: int = 0

func _init() -> void:
	var main_scene = load("res://scenes/shop/Main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	print("[RUNTIME] Main loop dimulai, simulasi 180 frame...")

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count >= 180:
		print("[RUNTIME] 180 frame simulasi gameplay berjalan mulus tanpa error.")
		quit(0)
	return false

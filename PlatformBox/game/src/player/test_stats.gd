extends MarginContainer

func _physics_process(delta):
	$HBoxContainer/VBoxContainer/stat_1.text = "FPS: " + str(Engine.get_frames_per_second())
	$HBoxContainer/VBoxContainer/stat_2.text = "Memory Static: " + str(round(Performance.get_monitor(Performance.MEMORY_STATIC)/1024/1024)) + "MB"
	Engine.max_fps = 60

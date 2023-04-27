extends Control




func _on_test_level_1_pressed():
	get_tree().change_scene_to_file("res://game/src/levels/test_level.tscn")


func _on_test_level_2_pressed():
	get_tree().change_scene_to_file("res://game/src/levels/test_level_2.tscn")


func _on_test_level_3_pressed():
	get_tree().change_scene_to_file("res://game/src/levels/test_level_3.tscn")


func _on_back_pressed():
	get_tree().change_scene_to_file("res://game/src/menu/menu.tscn")

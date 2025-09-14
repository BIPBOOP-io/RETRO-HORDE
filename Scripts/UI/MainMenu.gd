extends Control

func _on_play_pressed():
	get_tree().change_scene_to_file("res://Scenes/Main/Main.tscn")

func _on_records_pressed():
	get_tree().change_scene_to_file("res://Scenes/UI/RecordsMenu.tscn")

func _on_quit_pressed():
	get_tree().quit()

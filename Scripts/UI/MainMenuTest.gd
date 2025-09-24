extends Node

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main/Main.tscn")
	
func _on_upgrades_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/RecordsMenu.tscn")
	
func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/OptionsMenuTest.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

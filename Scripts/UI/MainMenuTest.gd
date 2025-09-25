extends Node

const MAIN_SCENE      := preload("res://Scenes/Main/Main.tscn")
const RECORDS_SCENE   := preload("res://Scenes/UI/RecordsMenu.tscn")
const OPTIONS_SCENE   := preload("res://Scenes/UI/OptionsMenuTest.tscn")

func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(MAIN_SCENE)

func _on_upgrades_pressed() -> void:
	get_tree().change_scene_to_packed(RECORDS_SCENE)

func _on_options_pressed() -> void:
	Global.previous_scene = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_packed(OPTIONS_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _ready() -> void:
	$MarginContainer/VBoxContainer/Center/PlayButton.grab_focus()

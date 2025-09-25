extends Node

const MAIN_SCENE    := preload("res://Scenes/Main/Main.tscn")
const RECORDS_SCENE := preload("res://Scenes/UI/RecordsMenu.tscn")
const OPTIONS_SCENE := preload("res://Scenes/UI/OptionsMenuTest.tscn")

@onready var play_button = $MarginContainer/VBoxContainer/Center/PlayButton

func _ready() -> void:
	play_button.grab_focus()

func _on_play_pressed() -> void:
	SceneLoader.change_scene_to_packed(MAIN_SCENE, SceneLoader.Direction.UP)

func _on_upgrades_pressed() -> void:
	SceneLoader.change_scene_to_packed(RECORDS_SCENE)

func _on_options_pressed() -> void:
	Global.previous_scene = get_tree().current_scene.scene_file_path
	SceneLoader.change_scene_to_packed(OPTIONS_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

extends Node

const MAIN_SCENE    := preload("res://Scenes/Main/Main.tscn")
const RECORDS_SCENE := preload("res://Scenes/UI/RecordsMenu.tscn")
const OPTIONS_SCENE := preload("res://Scenes/UI/OptionsMenu.tscn")

@onready var play_button = $MarginContainer/VBoxContainer/Center/PlayButton
@onready var version_label: Label = $MarginContainer/VBoxContainer/Footer/VersionLabel

func _ready() -> void:
	version_label.text = "v" + str(ProjectSettings.get_setting("application/config/version"))

func _on_play_pressed() -> void:
	SceneLoader.go_to(MAIN_SCENE, SceneLoader.Direction.DOWN)

func _on_upgrades_pressed() -> void:
	SceneLoader.go_to(RECORDS_SCENE, SceneLoader.Direction.RIGHT)

func _on_options_pressed() -> void:
	SceneLoader.go_to(OPTIONS_SCENE, SceneLoader.Direction.RIGHT)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

extends Control

@onready var layout_option: OptionButton = $Margin/VBox/Row/LayoutOption
@onready var back_button: Button = $Margin/VBox/Buttons/BackButton

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	_populate_layouts()

func _populate_layouts():
	layout_option.clear()
	layout_option.add_item("QWERTY")
	layout_option.add_item("AZERTY")

	var settings = get_node("/root/Settings")
	var idx := 0 if str(settings.layout).to_lower() == "qwerty" else 1
	layout_option.select(idx)
	if not layout_option.item_selected.is_connected(_on_layout_selected):
		layout_option.item_selected.connect(_on_layout_selected)

func _on_layout_selected(index: int):
	var target := "qwerty" if index == 0 else "azerty"
	var settings = get_node("/root/Settings")
	settings.set_layout(target)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		_on_back_pressed()

extends CanvasLayer

@onready var root_menu: VBoxContainer = $Panel/RootMenu
@onready var options_menu: VBoxContainer = $Panel/OptionsMenu
@onready var layout_option: OptionButton = $Panel/OptionsMenu/LayoutRow/LayoutOption

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_show_root()
	_populate_layouts()

func _show_root():
	root_menu.visible = true
	options_menu.visible = false

func _show_options():
	root_menu.visible = false
	options_menu.visible = true

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

func _on_resume_pressed():
	get_tree().paused = false
	visible = false

func _on_options_pressed():
	_show_options()

func _on_options_back_pressed():
	_show_root()

func _on_quit_pressed():
	# Intentionally do not save the run when quitting from pause.
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	# Only react to ESC when the pause menu is currently visible
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		# If currently in the options sub-menu, go back to root first.
		if options_menu.visible:
			_show_root()
		else:
			_on_resume_pressed()
			get_viewport().set_input_as_handled()

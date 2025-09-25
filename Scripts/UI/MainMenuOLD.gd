extends Control

var _buttons: Array[Button] = []
var _focus_index: int = 0
const HOVER_COLOR := Color(1, 0.4, 0.254902, 1)

func _ready():
	# Collect buttons in visual order
	var container = $UI/VBoxContainer/VBoxContainer if has_node("UI/VBoxContainer/VBoxContainer") else null
	if container:
		var children = container.get_children()
		for i in range(children.size()):
			var child = children[i]
			if child is Button:
				var b: Button = child
				b.focus_mode = Control.FOCUS_NONE   # prevent default white focus outline
				# Sync keyboard selection when mouse hovers a button
				if not b.mouse_entered.is_connected(_on_button_mouse_entered):
					b.mouse_entered.connect(_on_button_mouse_entered.bind(b))
				_buttons.append(b)
	if _buttons.size() > 0:
		_focus_index = 0
		_apply_highlight()

func _on_play_pressed():
	get_tree().change_scene_to_file("res://Scenes/Main/Main.tscn")

func _on_records_pressed():
	get_tree().change_scene_to_file("res://Scenes/UI/RecordsMenu.tscn")

func _on_options_pressed():
	get_tree().change_scene_to_file("res://Scenes/UI/OptionsMenu.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		_move_focus(-1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_down"):
		_move_focus(1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_activate_focused()

func _move_focus(dir: int):
	if _buttons.is_empty():
		return
	# Wrap-around, keep our internal index only
	_focus_index = int((_focus_index + dir + _buttons.size()) % _buttons.size())
	_apply_highlight()

func _activate_focused():
	if _buttons.is_empty():
		return
	_buttons[_focus_index].emit_signal("pressed")

func _on_button_mouse_entered(b: Button) -> void:
	var idx := _buttons.find(b)
	if idx != -1:
		_focus_index = idx
		_apply_highlight()

func _apply_highlight():
	for i in range(_buttons.size()):
		var b := _buttons[i]
		if i == _focus_index:
			b.add_theme_color_override("font_color", HOVER_COLOR)
			b.add_theme_color_override("font_hover_color", HOVER_COLOR)
		else:
			b.add_theme_color_override("font_color", Color(1,1,1,1))
			b.add_theme_color_override("font_hover_color", Color(1,1,1,1))

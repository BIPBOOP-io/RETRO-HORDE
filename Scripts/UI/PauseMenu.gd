extends CanvasLayer

@onready var root_menu: VBoxContainer = $Panel/RootMenu
@onready var options_menu: VBoxContainer = $Panel/OptionsMenu
@onready var layout_option: OptionButton = $Panel/OptionsMenu/LayoutRow/LayoutOption
@onready var upgrades_label: Label = $Panel/UpgradeContainer/MarginContainer/UpgradesList

var _buttons: Array[Button] = []
var _focus_index: int = 0
const HOVER_COLOR := Color(1, 0.4, 0.254902, 1)

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_show_root()
	_setup_buttons()
	_populate_layouts()
	if not self.visibility_changed.is_connected(_on_visibility_changed):
		self.visibility_changed.connect(_on_visibility_changed)

func _show_root():
	root_menu.visible = true
	options_menu.visible = false
	_refresh_upgrades()

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
	# Only react when visible
	if not visible:
		return
	# ESC closes, P also closes
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if options_menu.visible:
			_show_root()
		else:
			_on_resume_pressed()
		get_viewport().set_input_as_handled()
		return
	# Keyboard navigation (root menu only)
	if not options_menu.visible:
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

func _on_visibility_changed():
	if visible and not options_menu.visible:
		_refresh_upgrades()

func _refresh_upgrades():
	if upgrades_label == null:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		upgrades_label.text = ""
		return
	var um = player.get("upgrade_manager")
	if um == null:
		upgrades_label.text = ""
		return
	var levels = um.get("upgrades_level")
	if typeof(levels) != TYPE_DICTIONARY:
		upgrades_label.text = ""
		return
	var entries: Array = []
	for id in levels.keys():
		var lvl: int = int(levels[id])
		if lvl > 0:
			var title: String = str(um.get_title(id))
			entries.append({"title": title, "lvl": lvl})
	# sort by level desc then title asc
	entries.sort_custom(func(a, b):
		var la = int(a["lvl"]) ; var lb = int(b["lvl"])
		if la == lb: return str(a["title"]) < str(b["title"]) ;
		return la > lb)
	var lines: Array[String] = []
	for e in entries:
		lines.append("%s Lv %d" % [str(e["title"]), int(e["lvl"])])
	upgrades_label.text = ("\n".join(lines)) if lines.size() > 0 else ""

func _setup_buttons():
	_buttons.clear()
	if root_menu:
		var children = root_menu.get_children()
		for i in range(children.size()):
			var c = children[i]
			if c is Button:
				var b: Button = c
				b.focus_mode = Control.FOCUS_NONE
				if not b.mouse_entered.is_connected(_on_button_mouse_entered):
					b.mouse_entered.connect(_on_button_mouse_entered.bind(b))
				_buttons.append(b)
	if _buttons.size() > 0:
		_focus_index = 0
		_apply_highlight()

func _move_focus(dir: int):
	if _buttons.is_empty():
		return
	_focus_index = int((_focus_index + dir + _buttons.size()) % _buttons.size())
	_apply_highlight()

func _activate_focused():
	if _buttons.is_empty():
		return
	_buttons[_focus_index].emit_signal("pressed")

func _apply_highlight():
	for i in range(_buttons.size()):
		var b := _buttons[i]
		if i == _focus_index:
			b.add_theme_color_override("font_color", HOVER_COLOR)
			b.add_theme_color_override("font_hover_color", HOVER_COLOR)
		else:
			b.add_theme_color_override("font_color", Color(1,1,1,1))
			b.add_theme_color_override("font_hover_color", Color(1,1,1,1))

func _on_button_mouse_entered(b: Button) -> void:
	var idx := _buttons.find(b)
	if idx != -1:
		_focus_index = idx
		_apply_highlight()

extends Control

signal upgrade_chosen(upgrade: String)

@onready var option1: Button = $ColorRect/VBoxContainer/Option1
@onready var option2: Button = $ColorRect/VBoxContainer/Option2
@onready var option3: Button = $ColorRect/VBoxContainer/Option3

var upgrades: Array = []
var _buttons: Array[Button] = []
var _focus_index: int = 0
var _selection_locked: bool = false
var _base_texts: Array[String] = ["", "", ""]
const HOVER_COLOR := Color(1, 0.4, 0.254902, 1)
var _base_colors := {}

func _ready():
	# Hide menu on start
	visible = false
	_buttons = [option1, option2, option3]
	for b in _buttons:
		if b:
			b.focus_mode = Control.FOCUS_NONE
			if not b.mouse_entered.is_connected(_on_option_mouse_entered):
				b.mouse_entered.connect(_on_option_mouse_entered.bind(b))

func show_upgrades(options: Array):
	upgrades = options
	_selection_locked = false

	# If there are no options, close the menu without pausing
	if upgrades.is_empty():
		visible = false
		get_tree().paused = false
		return

	visible = true
	get_tree().paused = true

	# Retrieve the upgrade manager via the player
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var upgrade_manager = player.upgrade_manager

	var buttons: Array = [
		$ColorRect/VBoxContainer/Option1,
		$ColorRect/VBoxContainer/Option2,
		$ColorRect/VBoxContainer/Option3
	]

	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		if i < upgrades.size():
			var upgrade_id = upgrades[i]
			var data: Dictionary = upgrade_manager.upgrades_data[upgrade_id]

			btn.disabled = false
			btn.visible = true
			btn.text = "%s (%d/%d)" % [
				upgrade_manager.get_title(upgrade_id),
				upgrade_manager.upgrades_level[upgrade_id],
				int(data.get("max_level", 1))
			]
			_base_texts[i] = btn.text

			# color based on rarity (keep text color; selection uses focus style)
			var rarity = str(data.get("rarity", "common"))
			var base_col := Color(1,1,1)
			match rarity:
				"common": base_col = Color(1,1,1)
				"uncommon": base_col = Color(0.2, 0.9, 0.2)
				"rare": base_col = Color(0.4,0.6,1)
				"epic": base_col = Color(0.7,0.3,0.9)
				"legendary": base_col = Color(1,0.6,0)
			btn.add_theme_color_override("font_color", base_col)
			btn.add_theme_color_override("font_hover_color", base_col)
			btn.add_theme_color_override("font_focus_color", base_col)
			_base_colors[btn] = base_col
			# Tooltip with rarity
			btn.tooltip_text = rarity.capitalize()
		else:
			btn.disabled = true
			btn.visible = false
			_base_colors.erase(btn)

	# focus the first available option
	_focus_first_available()
	_apply_selection_visuals()

func _focus_first_available():
	_focus_index = 0
	var vis = _get_visible_buttons()
	if vis.size() > 0:
		_focus_index = 0

func _get_visible_buttons() -> Array[Button]:
	var res: Array[Button] = []
	for b in _buttons:
		if b and b.visible and not b.disabled:
			res.append(b)
	return res

func _move_focus(dir: int):
	var vis: Array[Button] = _get_visible_buttons()
	if vis.is_empty():
		return
	# Sync with actual focused item if any, then wrap-around
	# We don't rely on Control focus anymore (buttons have FOCUS_NONE)
	_focus_index = int((_focus_index + dir + vis.size()) % vis.size())
	# No grab_focus here; selection is handled by index
	_apply_selection_visuals()

func _activate_focused():
	var vis: Array[Button] = _get_visible_buttons()
	if vis.is_empty():
		return
	var btn: Button = vis[_focus_index]
	if btn:
		# Map back to original button index to avoid relying on pressed connections
		var orig_idx := _buttons.find(btn)
		if orig_idx != -1:
			_on_option_pressed(orig_idx)

func _on_option_mouse_entered(b: Button) -> void:
	var vis := _get_visible_buttons()
	var idx := vis.find(b)
	if idx != -1:
		_focus_index = idx
		# No grab_focus; keep keyboard selection index-only
		_apply_selection_visuals()

func _apply_highlight():
	pass

func _apply_selection_visuals():
	# Adds a simple chevron to the selected option without changing rarity colors
	for i in range(_buttons.size()):
		var btn = _buttons[i]
		if btn == null:
			continue
		if not btn.visible or btn.disabled:
			continue
		var base: String
		if i < _base_texts.size():
			base = _base_texts[i]
		else:
			base = btn.text
		if i == _focus_index:
			btn.text = "» " + base + " «"
		else:
			btn.text = base

func _on_option_pressed(index: int):
	if _selection_locked:
		return
	_selection_locked = true
	emit_signal("upgrade_chosen", upgrades[index])
	visible = false
	get_tree().paused = false

# These functions are triggered by signals connected in the editor
func _on_option_1_pressed(): _on_option_pressed(0)
func _on_option_2_pressed(): _on_option_pressed(1)
func _on_option_3_pressed(): _on_option_pressed(2)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	# Navigation: ui_up/ui_down already mapped to Z/W and S via Settings
	if event.is_action_pressed("ui_up"):
		_move_focus(-1)
		accept_event()
		return
	if event.is_action_pressed("ui_down"):
		_move_focus(1)
		accept_event()
		return
	# Activate: Enter/Space via ui_accept; also allow 'special' (Space) explicitly
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("special"):
		accept_event()
		_activate_focused()

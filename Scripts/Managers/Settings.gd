extends Node

const CONFIG_PATH := "user://settings.cfg"

# Supported layouts: "qwerty" or "azerty"
var layout: String = "qwerty"
var debug_enemy_ranges: bool = false
var player_name: String = "Guest"

func _ready():
	_load_config()
	apply_input_layout()

func set_layout(new_layout: String) -> void:
	new_layout = new_layout.to_lower()
	if new_layout != "qwerty" and new_layout != "azerty":
		push_warning("Unknown layout '" + new_layout + "', keeping '" + layout + "'.")
		return
	if layout == new_layout:
		return
	layout = new_layout
	apply_input_layout()
	_save_config()

func apply_input_layout() -> void:
	# Ensure actions exist
	var actions = ["ui_up", "ui_down", "ui_left", "ui_right", "sprint", "special", "pause"]
	for a in actions:
		if not InputMap.has_action(a):
			InputMap.add_action(a)

	# Clear existing key events (keep non-key events intact)
	for a in actions:
		_clear_key_events(a)

	# Always keep arrow keys as fallback
	_add_key_event("ui_up", KEY_UP)
	_add_key_event("ui_down", KEY_DOWN)
	_add_key_event("ui_left", KEY_LEFT)
	_add_key_event("ui_right", KEY_RIGHT)

	# Sprint (Shift)
	_add_key_event("sprint", KEY_SHIFT)

	# Special ability (Space)
	_add_key_event("special", KEY_SPACE)

	# Pause (P)
	_add_key_event("pause", KEY_P)

	# Letter mapping depending on selected layout
	if layout == "azerty":
		# ZQSD
		_add_key_event("ui_up", KEY_Z)
		_add_key_event("ui_left", KEY_Q)
		_add_key_event("ui_down", KEY_S)
		_add_key_event("ui_right", KEY_D)
	else:
		# QWERTY: WASD
		_add_key_event("ui_up", KEY_W)
		_add_key_event("ui_left", KEY_A)
		_add_key_event("ui_down", KEY_S)
		_add_key_event("ui_right", KEY_D)

	# Note: we do NOT add physical scancode bindings here to keep
	# the selected layout exclusive (no dual Z/W behavior).

func _clear_key_events(action: String) -> void:
	var to_remove: Array = []
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			to_remove.append(ev)
	for ev in to_remove:
		InputMap.action_erase_event(action, ev)

func _add_key_event(action: String, keycode: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = keycode
	e.pressed = false
	InputMap.action_add_event(action, e)


func _load_config() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)
	if err == OK:
		layout = str(cfg.get_value("input", "layout", layout)).to_lower()
		debug_enemy_ranges = bool(cfg.get_value("debug", "enemy_ranges", debug_enemy_ranges))
		player_name = str(cfg.get_value("profile", "player_name", player_name))

func _save_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "layout", layout)
	cfg.set_value("debug", "enemy_ranges", debug_enemy_ranges)
	cfg.set_value("profile", "player_name", player_name)
	cfg.save(CONFIG_PATH)

func is_enemy_debug_on() -> bool:
	return debug_enemy_ranges

func set_enemy_debug(on: bool) -> void:
	debug_enemy_ranges = on
	_save_config()

func set_player_name(new_name: String) -> void:
	var n := new_name.strip_edges()
	if n == "":
		n = "Guest"
	player_name = n
	_save_config()

func get_player_name() -> String:
	return player_name

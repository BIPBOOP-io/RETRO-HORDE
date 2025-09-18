extends Node

const CONFIG_PATH := "user://settings.cfg"

# Supported layouts: "qwerty" or "azerty"
var layout: String = "qwerty"

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
	var actions = ["ui_up", "ui_down", "ui_left", "ui_right", "sprint", "special"]
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

func _save_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "layout", layout)
	cfg.save(CONFIG_PATH)

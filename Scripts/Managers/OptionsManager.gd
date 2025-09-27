extends Node

const SAVE_PATH := "user://settings.cfg"
var config := ConfigFile.new()

# keep track of where we came from
var previous_scene: String = ""

# --------------------------
# Onready node references
# --------------------------

# General
@onready var lang_button = $OptionsMenuMarginContainer/OptionsMenuVBoxContainer/MarginContainer/TabContainer/GENERAL/GeneralMarginContainer/GeneralVBoxContainer/LanguageHBoxContainer/LanguageOptionButton

# Audio
@onready var master_slider = $OptionsMenuMarginContainer/OptionsMenuVBoxContainer/MarginContainer/TabContainer/AUDIO/AudioMarginContainer/AudioVBoxContainer/MasterVolumeHBoxContainer/MasterVolumeHSlider
@onready var music_slider = $OptionsMenuMarginContainer/OptionsMenuVBoxContainer/MarginContainer/TabContainer/AUDIO/AudioMarginContainer/AudioVBoxContainer/MusicVolumeHBoxContainer/MusicVolumeHSlider
@onready var sfx_slider = $OptionsMenuMarginContainer/OptionsMenuVBoxContainer/MarginContainer/TabContainer/AUDIO/AudioMarginContainer/AudioVBoxContainer/SFXVolumeHBoxContainer/SFXVolumeHSlider
@onready var mute_checkbox = $OptionsMenuMarginContainer/OptionsMenuVBoxContainer/MarginContainer/TabContainer/AUDIO/AudioMarginContainer/AudioVBoxContainer/MuteAllHBoxContainer/MuteAllCheckBox

# Video
@onready var fullscreen_checkbox = $OptionsMenuMarginContainer/OptionsMenuVBoxContainer/MarginContainer/TabContainer/VIDEO/VideoMarginContainer/VideoVBoxContainer/FullscreenHBoxContainer/FullscreenCheckBox
@onready var vsync_checkbox = $OptionsMenuMarginContainer/OptionsMenuVBoxContainer/MarginContainer/TabContainer/VIDEO/VideoMarginContainer/VideoVBoxContainer/VSyncHBoxContainer/VSyncCheckBox

# Controls (placeholders)
@onready var invert_y_checkbox = $OptionsMenuMarginContainer/OptionsMenuVBoxContainer/MarginContainer/TabContainer/CONTROLS/ControlsMarginContainer/ControlsVBoxContainer/InvertYAxisHBoxContainer/InvertYAxisCheckBox
@onready var input_device_button = $OptionsMenuMarginContainer/OptionsMenuVBoxContainer/MarginContainer/TabContainer/CONTROLS/ControlsMarginContainer/ControlsVBoxContainer/InputDeviceHBoxContainer/InputDeviceOptionButton

# Accessibility
@onready var ui_scale_slider = $OptionsMenuMarginContainer/OptionsMenuVBoxContainer/MarginContainer/TabContainer/ACCESSIBILITY/AccessibilityMarginContainer/AccessibilityVBoxContainer/UIScaleHBoxContainer/UIScaleHSlider
@onready var text_speed_slider = $OptionsMenuMarginContainer/OptionsMenuVBoxContainer/MarginContainer/TabContainer/ACCESSIBILITY/AccessibilityMarginContainer/AccessibilityVBoxContainer/TextSpeedHBoxContainer/TextSpeedHSlider
@onready var colorblind_button = $OptionsMenuMarginContainer/OptionsMenuVBoxContainer/MarginContainer/TabContainer/ACCESSIBILITY/AccessibilityMarginContainer/AccessibilityVBoxContainer/ColorblindModeHBoxContainer/ColorblindModeOptionButton
@onready var heal_feedback_checkbox = $OptionsMenuMarginContainer/OptionsMenuVBoxContainer/MarginContainer/TabContainer/ACCESSIBILITY/AccessibilityMarginContainer/AccessibilityVBoxContainer/HealFeedbackHBoxContainer/HealFeedbackCheckBox if has_node("OptionsMenuMarginContainer/OptionsMenuVBoxContainer/MarginContainer/TabContainer/ACCESSIBILITY/AccessibilityMarginContainer/AccessibilityVBoxContainer/HealFeedbackHBoxContainer/HealFeedbackCheckBox") else null

@onready var back_button = $OptionsMenuMarginContainer/OptionsMenuVBoxContainer/BackButton

# --------------------------
# Lifecycle
# --------------------------

func _ready() -> void:
	# store previous scene path (if available)
	if get_tree().current_scene and get_tree().current_scene.scene_file_path != "":
		previous_scene = get_tree().current_scene.scene_file_path

	_load_settings()
	_connect_signals()
	back_button.pressed.connect(_on_back_button_pressed)


# --------------------------
# Save & Load
# --------------------------

func _save_setting(section: String, key: String, value) -> void:
	config.set_value(section, key, value)
	config.save(SAVE_PATH)

func _load_settings() -> void:
	var err = config.load(SAVE_PATH)
	if err != OK:
		return # no file yet

	# General
	if config.has_section_key("general", "language"):
		var idx = config.get_value("general", "language")
		lang_button.select(idx)
		_apply_language(idx)

	# Audio
	if config.has_section_key("audio", "master"):
		var v = config.get_value("audio", "master")
		master_slider.value = v
		_apply_audio("Master", v)

	if config.has_section_key("audio", "music"):
		var v = config.get_value("audio", "music")
		music_slider.value = v
		_apply_audio("Music", v)

	if config.has_section_key("audio", "sfx"):
		var v = config.get_value("audio", "sfx")
		sfx_slider.value = v
		_apply_audio("SFX", v)

	if config.has_section_key("audio", "mute_all"):
		var mute = config.get_value("audio", "mute_all")
		mute_checkbox.button_pressed = mute
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), mute)

	# Video
	if config.has_section_key("video", "fullscreen"):
		var fs = config.get_value("video", "fullscreen")
		fullscreen_checkbox.button_pressed = fs
		_apply_fullscreen(fs)

	if config.has_section_key("video", "vsync"):
		var vs = config.get_value("video", "vsync")
		vsync_checkbox.button_pressed = vs
		_apply_vsync(vs)

	# Controls
	if config.has_section_key("controls", "invert_y"):
		invert_y_checkbox.button_pressed = config.get_value("controls", "invert_y")

	if config.has_section_key("controls", "input_device"):
		input_device_button.select(config.get_value("controls", "input_device"))

	# Accessibility
	if config.has_section_key("accessibility", "ui_scale"):
		var s = config.get_value("accessibility", "ui_scale")
		ui_scale_slider.value = s
		_apply_ui_scale(s)

	if config.has_section_key("accessibility", "text_speed"):
		text_speed_slider.value = config.get_value("accessibility", "text_speed")

	if config.has_section_key("accessibility", "colorblind_mode"):
		colorblind_button.select(config.get_value("accessibility", "colorblind_mode"))

	# Heal HP feedback
	if heal_feedback_checkbox != null:
		var enabled: bool = bool(config.get_value("accessibility", "heal_feedback", true))
		heal_feedback_checkbox.button_pressed = enabled
		if has_node("/root/Settings"):
			get_node("/root/Settings").set_heal_feedback(enabled)


# --------------------------
# Apply Functions
# --------------------------

func _apply_audio(bus_name: String, value: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))

func _apply_fullscreen(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_vsync(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _apply_language(index: int) -> void:
	var lang = lang_button.get_item_text(index)
	TranslationServer.set_locale(lang)

func _apply_ui_scale(value: float) -> void:
	get_tree().root.content_scale_factor = value


# --------------------------
# Connect Signals
# --------------------------

func _connect_signals() -> void:
	# General
	lang_button.item_selected.connect(func(i): _apply_language(i); _save_setting("general", "language", i))

	# Audio
	master_slider.value_changed.connect(func(v): _apply_audio("Master", v); _save_setting("audio", "master", v))
	music_slider.value_changed.connect(func(v): _apply_audio("Music", v); _save_setting("audio", "music", v))
	sfx_slider.value_changed.connect(func(v): _apply_audio("SFX", v); _save_setting("audio", "sfx", v))
	mute_checkbox.toggled.connect(func(pressed): AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), pressed); _save_setting("audio", "mute_all", pressed))

	# Video
	fullscreen_checkbox.toggled.connect(func(pressed): _apply_fullscreen(pressed); _save_setting("video", "fullscreen", pressed))
	vsync_checkbox.toggled.connect(func(pressed): _apply_vsync(pressed); _save_setting("video", "vsync", pressed))

	# Controls
	invert_y_checkbox.toggled.connect(func(pressed): _save_setting("controls", "invert_y", pressed))
	input_device_button.item_selected.connect(func(i): _save_setting("controls", "input_device", i))

	# Accessibility
	ui_scale_slider.value_changed.connect(func(v): _apply_ui_scale(v); _save_setting("accessibility", "ui_scale", v))
	text_speed_slider.value_changed.connect(func(v): _save_setting("accessibility", "text_speed", v))
	colorblind_button.item_selected.connect(func(i): _save_setting("accessibility", "colorblind_mode", i))
	if heal_feedback_checkbox != null:
		heal_feedback_checkbox.toggled.connect(func(pressed):
			_save_setting("accessibility", "heal_feedback", pressed)
			if has_node("/root/Settings"):
				get_node("/root/Settings").set_heal_feedback(pressed)
		)


# --------------------------
# Back Button
# --------------------------

func _on_back_button_pressed() -> void:
	if Global.previous_scene != "":
		SceneLoader.change_scene_to_file(Global.previous_scene, SceneLoader.Direction.LEFT)
	else:
		get_tree().quit()

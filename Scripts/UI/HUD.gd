extends CanvasLayer

var xp_bar: TextureProgressBar
var level_label: Label
var hp_bar: TextureProgressBar
var timer_label: Label
var kills_label: Label
var stamina_bar: TextureProgressBar
var special_bar: TextureProgressBar

func _ready():
	xp_bar = $XpBar
	level_label = $Control/MarginContainer/VBoxContainer/LevelLabel
	hp_bar = $HpBar
	timer_label = $Control/MarginContainer/VBoxContainer/TimerLabel
	kills_label = $Control/MarginContainer/VBoxContainer/KillsLabel
	stamina_bar = $StaminaBar if has_node("StaminaBar") else null
	special_bar = $SpecialBar if has_node("SpecialBar") else null

# ==========================
#        XP & LEVEL
# ==========================
func update_xp(current_xp: int, xp_to_next: int):
	if xp_bar == null: xp_bar = $XpBar
	xp_bar.max_value = xp_to_next
	xp_bar.value = current_xp

func update_level(level: int):
	if level_label == null: level_label = $Control/MarginContainer/VBoxContainer/LevelLabel
	level_label.text = "Level : %d" % level

# ==========================
#        HEALTH
# ==========================
func update_health(current_hp: int, max_hp: int):
	if hp_bar == null: hp_bar = $HpBar
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp

# ==========================
#        STAMINA
# ==========================
func update_stamina(current: float, max_value: float):
	if stamina_bar == null and has_node("StaminaBar"): stamina_bar = $StaminaBar
	if stamina_bar:
		stamina_bar.max_value = max_value
		stamina_bar.value = current

# ==========================
#        SPECIAL
# ==========================
func update_special(current: float, max_value: float):
	if special_bar == null and has_node("SpecialBar"): special_bar = $SpecialBar
	if special_bar:
		special_bar.max_value = max_value
		special_bar.value = clamp(current, 0.0, max_value)

# ==========================
#       TIMER & KILLS
# ==========================
func update_timer(seconds: int):
	if timer_label == null: timer_label = $Control/MarginContainer/VBoxContainer/TimerLabel
	@warning_ignore("integer_division")
	var minutes = seconds / 60
	var secs = seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, secs]

func update_kills(kills: int):
	if kills_label == null: kills_label = $Control/MarginContainer/VBoxContainer/KillsLabel
	kills_label.text = "Kills : %d" % kills

# ==========================
#       TOAST (UPGRADES)
# ==========================
func show_upgrade_toast(text: String):
	var lbl := Label.new()
	lbl.text = "+ " + text
	lbl.add_theme_color_override("font_color", Color(1,1,1,1))
	lbl.add_theme_color_override("font_outline_color", Color(0,0,0,1))
	lbl.add_theme_constant_override("outline_size", 8)
	add_child(lbl)
	lbl.top_level = true
	var vp_size = get_viewport().get_visible_rect().size
	lbl.position = Vector2(vp_size.x - 280, vp_size.y - 100)
	var tween = create_tween()
	lbl.modulate.a = 1.0
	tween.tween_property(lbl, "position:y", lbl.position.y - 30, 1.2)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tween.tween_callback(lbl.queue_free)

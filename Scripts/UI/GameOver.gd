extends Control

@onready var time_label:  Label = $Margin/VBoxContainer/HBoxContainer/TimeLabel
@onready var kills_label: Label = $Margin/VBoxContainer/HBoxContainer/KillsLabel
@onready var level_label: Label = $Margin/VBoxContainer/HBoxContainer/LevelLabel
@onready var score_label: Label = $Margin/VBoxContainer/ScoreLabel if has_node("Margin/VBoxContainer/ScoreLabel") else null
@onready var best_label:  Label = $Margin/VBoxContainer/BestLabel if has_node("Margin/VBoxContainer/BestLabel") else null
@onready var name_edit:   LineEdit = $Margin/VBoxContainer/NameRow/NameEdit if has_node("Margin/VBoxContainer/NameRow/NameEdit") else null

var _score_sent: bool = false

func _ready():
	var data = Global.score_data
	var t     = int(data.get("duration", 0))
	var kills = int(data.get("kills", 0))
	var lvl   = int(data.get("level", 1))
	var score = int(data.get("score", (kills * 10) + (lvl * 100) + (t * 2))) # fallback for older runs

	# Time format
	@warning_ignore("integer_division")
	var m = t / 60
	var s = t % 60
	time_label.text  = "TIME : %02d:%02d" % [m, s]
	kills_label.text = "KILLS : %d" % kills
	level_label.text = "LEVEL : %d" % lvl

	if score_label:
		score_label.text = "SCORE : %d" % score

	# Prefill player name input
	if name_edit:
		var default_name := "Guest"
		if "player_name" in Global:
			default_name = String(Global.player_name)
		name_edit.text = default_name
		name_edit.text_submitted.connect(_on_name_submitted)
		name_edit.focus_exited.connect(_on_name_focus_exited)
		name_edit.grab_focus()

	# --- Best score (arcade-style) ---
	var all_stats: Array = SaveManager.load_stats()
	if all_stats.size() > 0:
		var best: Dictionary = all_stats[0]
		for entry in all_stats:
			var e: Dictionary = entry
			if int(e.get("score", 0)) > int(best.get("score", 0)):
				best = e

		if best_label:
			var bt = int(best.get("duration", 0))
			@warning_ignore("integer_division")
			var bm = bt / 60
			var bs = bt % 60
			best_label.text = "RECORD :\n %d PTS | %d KILLS | LEVEL %d | TIME : %02d:%02d" % [
				int(best.get("score", 0)),
				int(best.get("kills", 0)),
				int(best.get("level", 1)),
				bm, bs
			]

	# Do not send score immediately; wait for user name entry or action.


# --------------------------
#   Network
# --------------------------

func _send_score(player_name: String, kills: int, level: int, duration: int, device: String, version: String = "") -> void:
	if version == "" or version == "EMPTY":
		version = str(ProjectSettings.get_setting("application/config/version", "dev"))

	var computed_score := int(Global.score_data.get("score", Global.calculate_score({
		"kills": kills,
		"level": level,
		"duration": duration
	})))

	await Score.submit_score(player_name, kills, level, duration, device, version, computed_score)
	print("✅ Score sent to Supabase for %s (v%s)" % [player_name, version])
	_score_sent = true

func _ensure_submit() -> void:
	if _score_sent:
		return
	var data = Global.score_data
	var t     = int(data.get("duration", 0))
	var kills = int(data.get("kills", 0))
	var lvl   = int(data.get("level", 1))
	var device: String = OS.get_name().to_lower()
	var version: String = ProjectSettings.get_setting("application/config/version", "dev")
	var player_name: String = name_edit.text if name_edit else ("%s" % ("Guest"))
	if player_name.strip_edges() == "":
		player_name = "Guest"
	Global.player_name = player_name
	await _send_score(player_name, kills, lvl, t, device, version)


# --------------------------
#   Navigation
# --------------------------

func _on_replay_button_pressed():
	await _ensure_submit()
	get_tree().change_scene_to_file("res://Scenes/Main/Main.tscn")

func _on_main_menu_button_pressed():
	await _ensure_submit()
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

# --------------------------
#   Name input handlers
# --------------------------

func _on_name_submitted(new_text: String) -> void:
	if new_text.strip_edges() != "":
		Global.player_name = new_text.strip_edges()
		# Optionally auto-submit upon Enter
		await _ensure_submit()

func _on_name_focus_exited() -> void:
	if name_edit:
		var t := name_edit.text.strip_edges()
		if t != "":
			Global.player_name = t

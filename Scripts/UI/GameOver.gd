extends Control

@onready var time_label:  Label = $Margin/VBoxContainer/HBoxContainer/TimeLabel
@onready var kills_label: Label = $Margin/VBoxContainer/HBoxContainer/KillsLabel
@onready var level_label: Label = $Margin/VBoxContainer/HBoxContainer/LevelLabel
@onready var score_label: Label = $Margin/VBoxContainer/ScoreLabel if has_node("Margin/VBoxContainer/ScoreLabel") else null
@onready var best_label:  Label = $Margin/VBoxContainer/BestLabel if has_node("Margin/VBoxContainer/BestLabel") else null

func _ready():
	var data = Global.score_data
	var t     = int(data.get("duration", 0))
	var kills = int(data.get("kills", 0))
	var lvl   = int(data.get("level", 1))
	var score = int(data.get("score", (kills * 10) + (lvl * 100) + (t * 2))) # fallback si vieux run

	# Format temps
	var m = t / 60
	var s = t % 60
	time_label.text  = "Temps : %02d:%02d" % [m, s]
	kills_label.text = "Kills : %d" % kills
	level_label.text = "Niveau : %d" % lvl

	if score_label:
		score_label.text = "Score : %d" % score

	# --- Meilleur score (par score arcade) ---
	var all_stats: Array = SaveManager.load_stats()
	if all_stats.size() > 0:
		var best: Dictionary = all_stats[0]
		for entry in all_stats:
			var e: Dictionary = entry
			if int(e.get("score", 0)) > int(best.get("score", 0)):
				best = e

		# Affichage optionnel dans l'UI si BestLabel existe
		if best_label:
			var bt = int(best.get("duration", 0))
			var bm = bt / 60
			var bs = bt % 60
			best_label.text = "Record : %d pts – %d kills – Lvl %d – %02d:%02d" % [
				int(best.get("score", 0)),
				int(best.get("kills", 0)),
				int(best.get("level", 1)),
				bm, bs
			]

func _on_replay_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Main/Main.tscn")

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

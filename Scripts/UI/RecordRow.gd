extends HBoxContainer

@onready var name_label: Label  = $Name
@onready var score_label: Label = $Score
@onready var kills_label: Label = $Kills
@onready var level_label: Label = $Level
@onready var time_label: Label  = $Time
@onready var date_label: Label  = $Date
@onready var bg: ColorRect      = $ColorRect

func set_data(player_name: String, score: int, kills: int, level: int, time_str: String, date_str: String, is_alt: bool = false):
	# Sécurise l'accès si set_data est appelé avant _ready
	if name_label == null:  name_label  = $Name
	if score_label == null: score_label = $Score
	if kills_label == null: kills_label = $Kills
	if level_label == null: level_label = $Level
	if time_label == null:  time_label  = $Time
	if date_label == null:  date_label  = $Date

	print("➡ set_data:", player_name, score, kills, level, time_str, date_str, is_alt) # DEBUG

	if name_label:  name_label.text  = player_name
	if score_label: score_label.text = str(score)
	if kills_label: kills_label.text = str(kills)
	if level_label: level_label.text = str(level)
	if time_label:  time_label.text  = time_str
	if date_label:  date_label.text  = date_str

	# Fond alterné
	if bg:
		bg.color = Color(0,0,0,0.2) if is_alt else Color(0,0,0,0)

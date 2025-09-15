extends Control

@onready var list_container: VBoxContainer = $Margin/VBox/Scroll/List
@onready var back_button: Button = $Margin/VBox/Buttons/BackButton
@onready var title_label: Label = $Margin/VBox/Title

# On charge la scène RecordRow pour avoir plus de contrôle sur le design
var row_scene: PackedScene = preload("res://Scenes/UI/RecordRow.tscn")

func _ready():
	title_label.text = "Records"
	back_button.pressed.connect(_on_back_pressed)
	_populate_list()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

func _populate_list():
	# Nettoyer la liste
	for c in list_container.get_children():
		c.queue_free()

	var stats: Array = SaveManager.load_stats()

	if stats.is_empty():
		var empty = Label.new()
		empty.text = "No records yet."
		list_container.add_child(empty)
		return

	# Tri par score décroissant
	stats.sort_custom(Callable(self, "_sort_by_score_desc"))

	# Garder max 50 entrées
	stats = stats.slice(0, min(50, stats.size()))

	# Ajouter les lignes
	var i := 0
	for run in stats:
		print("📊 Ajout ligne:", run)
		var row = row_scene.instantiate()
		list_container.add_child(row)
		row.set_data(
			run.get("name", "Player"),        # Nom
			int(run.get("score", 0)),         # Score
			int(run.get("kills", 0)),         # Kills
			int(run.get("level", 1)),         # Level
			_format_time(int(run.get("duration", 0))),  # Temps formaté
			_format_date(run.get("date", "")), # Date formatée
			i % 2 == 1                        # alterne le fond
		)
		i += 1

func _sort_by_score_desc(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("score", 0)) > int(b.get("score", 0))

func _format_time(seconds: int) -> String:
	var m: int = int(seconds / 60)
	var s: int = seconds % 60
	return "%02d:%02d" % [m, s]

func _format_date(date_str: String) -> String:
	# Exemple: "2025-09-14T19:44:44" -> "2025-09-14 19:44"
	if "T" in date_str:
		var parts = date_str.split("T")
		if parts.size() == 2:
			return "%s %s" % [parts[0], parts[1].substr(0,5)]
	return date_str

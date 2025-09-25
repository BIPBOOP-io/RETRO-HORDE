extends Control

@onready var list_container: VBoxContainer = $Margin/VBox/Scroll/List
@onready var back_button: Button = $Margin/VBox/Buttons/BackButton
@onready var title_label: Label = $Margin/VBox/Title

var row_scene: PackedScene = preload("res://Scenes/UI/RecordRow.tscn")

func _ready() -> void:
	title_label.text = "Records"
	back_button.pressed.connect(_on_back_button_pressed)
	_populate_list()

# --------------------------
#   Navigation
# --------------------------

func _on_back_button_pressed() -> void:
	if Global.previous_scene != "":
		SceneLoader.change_scene_to_file(Global.previous_scene, SceneLoader.Direction.LEFT)
	else:
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		_on_back_button_pressed()

# --------------------------
#   Data
# --------------------------

func _populate_list() -> void:
	# Clear existing rows
	for c in list_container.get_children():
		c.queue_free()

	# Ajout d’un label temporaire "Loading..."
	var loading := Label.new()
	loading.text = "Loading leaderboard..."
	list_container.add_child(loading)

	# Récupération depuis Supabase
	_populate_from_supabase()

# Charge le leaderboard Supabase
func _populate_from_supabase() -> void:
	var rows: Array = await Score.get_leaderboard("survival_time", 50, true)

	# Clear "Loading..." message
	for c in list_container.get_children():
		c.queue_free()

	if rows.is_empty():
		var empty := Label.new()
		empty.text = "No records yet."
		list_container.add_child(empty)
		return

	# Ajoute les rows à la liste
	var i := 0
	for run in rows:
		var row = row_scene.instantiate()
		list_container.add_child(row)

		# Récupération sécurisée des champs (selon ton schema Supabase)
		@warning_ignore("shadowed_variable_base_class")
		var name: String = run.get("player_name", "Player")
		var kills: int = int(run.get("kills", 0))
		var level: int = int(run.get("level", 1))
		var time_sec: int = int(run.get("survival_time", 0))
		var date_str: String = run.get("created_at", "")

		row.set_data(
			name,
			kills,                        # Score (ici kills)
			kills,                        # Colonne kills
			level,                        # Colonne level
			_format_time(time_sec),       # Temps formaté
			_format_date(date_str),       # Date formatée
			i % 2 == 1                    # Alternance background
		)
		i += 1

# --------------------------
#   Helpers
# --------------------------

func _format_time(seconds: int) -> String:
	@warning_ignore("integer_division")
	var m: int = int(seconds / 60)
	var s: int = seconds % 60
	return "%02d:%02d" % [m, s]

func _format_date(date_str: String) -> String:
	if "T" in date_str:
		var parts: Array = date_str.split("T")
		if parts.size() >= 2:
			var d: String = str(parts[0])
			var t: String = str(parts[1])
			var dparts: Array = d.split("-")
			if dparts.size() == 3:
				var y: String = dparts[0]
				var m: String = dparts[1]
				var day: String = dparts[2]
				var yy: String = y.substr(max(0, y.length() - 2), 2)
				var hhmm: String = t.substr(0, 5)
				return "%s.%s.%s %s" % [day, m, yy, hhmm]
	return date_str

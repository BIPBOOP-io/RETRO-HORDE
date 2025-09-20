extends Control

@onready var list_container: VBoxContainer = $Margin/VBox/Scroll/List
@onready var back_button: Button = $Margin/VBox/Buttons/BackButton
@onready var title_label: Label = $Margin/VBox/Title

# Load RecordRow scene for better control over row design
var row_scene: PackedScene = preload("res://Scenes/UI/RecordRow.tscn")

func _ready():
	title_label.text = "Records"
	back_button.pressed.connect(_on_back_pressed)
	_populate_list()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		_on_back_pressed()

func _populate_list():
	# Clear existing rows
	for c in list_container.get_children():
		c.queue_free()

	var stats: Array = SaveManager.load_stats()

	if stats.is_empty():
		var empty = Label.new()
		empty.text = "No records yet."
		list_container.add_child(empty)
		return

	# Sort by score (descending)
	stats.sort_custom(Callable(self, "_sort_by_score_desc"))

	# Keep max 50 entries
	stats = stats.slice(0, min(50, stats.size()))

	# Add rows
	var i := 0
	for run in stats:
		var row = row_scene.instantiate()
		list_container.add_child(row)
		row.set_data(
			run.get("name", "Player"),        # Nom
			int(run.get("score", 0)),         # Score
			int(run.get("kills", 0)),         # Kills
			int(run.get("level", 1)),         # Level
			_format_time(int(run.get("duration", 0))),  # formatted time
			_format_date(run.get("date", "")),         # formatted date
			i % 2 == 1                                     # alternate background
		)
		i += 1

func _sort_by_score_desc(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("score", 0)) > int(b.get("score", 0))

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

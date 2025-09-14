extends Control

@onready var list_container: VBoxContainer = $Margin/VBox/Scroll/List
@onready var back_button: Button = $Margin/VBox/Buttons/BackButton
@onready var title_label: Label = $Margin/VBox/Title

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

	# Tri simple : par kills décroissants (tu peux switch sur date si tu préfères)
	stats.sort_custom(Callable(self, "_sort_by_kills_desc"))

	# (Option) Garde que les 50 derniers pour éviter des listes immenses:
	# stats = stats.slice(0, min(50, stats.size()))

	# En-tête
	list_container.add_child(_make_header_row())

	# Lignes
	for run in stats:
		list_container.add_child(_make_row(
			str(run.get("date", "")),
			int(run.get("kills", 0)),
			int(run.get("level", 1)),
			_format_time(int(run.get("duration", 0)))
		))

func _sort_by_kills_desc(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("kills", 0)) > int(b.get("kills", 0))

func _make_header_row() -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.add_child(_make_cell("Date", 220, true))
	row.add_child(_make_cell("Kills", 80, true))
	row.add_child(_make_cell("Level", 80, true))
	row.add_child(_make_cell("Time", 100, true))
	return row

func _make_row(date_str: String, kills: int, level: int, time_str: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.add_child(_make_cell(date_str, 220))
	row.add_child(_make_cell(str(kills), 80))
	row.add_child(_make_cell(str(level), 80))
	row.add_child(_make_cell(time_str, 100))
	return row

func _make_cell(text: String, min_width: int, is_header := false) -> Label:
	var l = Label.new()
	l.text = text
	l.custom_minimum_size.x = min_width
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if is_header:
		l.add_theme_color_override("font_color", Color(1, 1, 0.7))
		l.add_theme_font_size_override("font_size", 16)
	return l

func _format_time(seconds: int) -> String:
	var m = seconds / 60
	var s = seconds % 60
	return "%02d:%02d" % [m, s]

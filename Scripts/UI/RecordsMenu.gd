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
	for c in list_container.get_children():
		c.queue_free()

	var loading := Label.new()
	loading.text = "Loading leaderboard..."
	list_container.add_child(loading)

	_populate_from_supabase()

func _populate_from_supabase() -> void:
	var rows: Array = await Score.get_leaderboard("total_score", 50, true)

	for c in list_container.get_children():
		c.queue_free()

	if rows.is_empty():
		var empty := Label.new()
		empty.text = "No records yet."
		list_container.add_child(empty)
		return

	var i := 0
	for run in rows:
		var row = row_scene.instantiate()
		list_container.add_child(row)

		var player_name: String = run.get("player_name", "Player")
		var kills: int = int(run.get("kills", 0))
		var level: int = int(run.get("level", 1))
		var time_sec: int = int(run.get("survival_time", 0))
		var date_str: String = run.get("created_at", "")
		var score: int = int(run.get("total_score", Global.calculate_score({
			"kills": kills,
			"level": level,
			"duration": time_sec
		})))

		row.set_data(
			player_name,
			score,
			kills,
			level,
			_format_time(time_sec),
			_format_date(date_str),
			i % 2 == 1
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
	if date_str == "":
		return ""

	# Try to parse Supabase ISO 8601 (UTC) first.
	var utc_dict: Dictionary = Time.get_datetime_dict_from_datetime_string(date_str, true)

	# If parsing fails (e.g., due to fractional seconds or timezone suffix),
	# normalize the string to "YYYY-MM-DD HH:MM:SS" without TZ and try again.
	if utc_dict.is_empty():
		var s := date_str.strip_edges()
		# Replace 'T' with space
		var t := s.find("T")
		if t != -1:
			s = s.substr(0, t) + " " + s.substr(t + 1)
		# Drop fractional seconds
		var dot_idx := s.find(".")
		if dot_idx != -1:
			s = s.substr(0, dot_idx)
		# Remove trailing 'Z' or timezone offset like +02:00 / -05:00
		# (Search for +/- only after the original 'T' position to avoid date dashes.)
		var tz_cut := -1
		if t != -1:
			var after_t := s.substr(t)
			var plus_rel := after_t.find("+")
			var minus_rel := after_t.find("-")
			if plus_rel != -1:
				tz_cut = t + plus_rel
			elif minus_rel != -1:
				tz_cut = t + minus_rel
		if s.ends_with("Z"):
			s = s.substr(0, s.length() - 1)
		elif tz_cut != -1:
			s = s.substr(0, tz_cut)

		utc_dict = Time.get_datetime_dict_from_datetime_string(s, true)

	if utc_dict.is_empty():
		# As a last resort, return the raw server string.
		return date_str

	# Convert UTC → local using system timezone (handles DST automatically).
	var unix_time: int = Time.get_unix_time_from_datetime_dict(utc_dict)
	var local_dict: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)

	# Determine current app/user locale. Prefer game locale, fallback to OS.
	var locale: String = TranslationServer.get_locale().to_lower()
	if locale == "" or locale == "en":
		# If not explicitly set, try OS locale for better regional defaults.
		if OS.has_method("get_locale"):
			var os_loc = OS.get_locale()
			if typeof(os_loc) == TYPE_STRING and os_loc != "":
				locale = String(os_loc).to_lower()

	# Normalize some common region codes.
	var is_en_gb := locale.begins_with("en_gb") or locale.begins_with("en-gb")
	var is_en_us := locale.begins_with("en_us") or locale.begins_with("en-us") or locale == "en"
	var is_fr := locale.begins_with("fr")
	var is_de := locale.begins_with("de")
	var is_es := locale.begins_with("es")
	var is_it := locale.begins_with("it")
	var is_east_asia := locale.begins_with("ja") or locale.begins_with("zh") or locale.begins_with("ko")

	var yy: int = int(local_dict.year) % 100

	# Apply region-appropriate formatting.
	if is_fr or is_es or is_it or is_en_gb:
		# dd/MM/yy HH:mm (France, Spain, Italy, UK)
		return "%02d/%02d/%02d %02d:%02d" % [
			local_dict.day, local_dict.month, yy, local_dict.hour, local_dict.minute
		]
	elif is_de:
		# dd.MM.yy HH:mm (Germany)
		return "%02d.%02d.%02d %02d:%02d" % [
			local_dict.day, local_dict.month, yy, local_dict.hour, local_dict.minute
		]
	elif is_en_us:
		# MM/dd/yy HH:mm (US)
		return "%02d/%02d/%02d %02d:%02d" % [
			local_dict.month, local_dict.day, yy, local_dict.hour, local_dict.minute
		]
	elif is_east_asia:
		# yy/MM/dd HH:mm (JP/CN/KR common ordering)
		return "%02d/%02d/%02d %02d:%02d" % [
			yy, local_dict.month, local_dict.day, local_dict.hour, local_dict.minute
		]
	else:
		# Fallback: full ISO-like local with 24h time
		return "%04d-%02d-%02d %02d:%02d" % [
			local_dict.year, local_dict.month, local_dict.day, local_dict.hour, local_dict.minute
		]

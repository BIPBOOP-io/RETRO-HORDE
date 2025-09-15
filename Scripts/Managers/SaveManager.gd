# res://Scripts/Managers/SaveManager.gd
extends Node
class_name SaveManager

const SAVE_PATH = "user://scores.save"

# ==========================
# Sauvegarde une partie
# ==========================
static func save_game(duration: int, kills: int, level: int) -> void:
	var stats = load_stats()
	stats.append({
		"duration": duration,
		"kills": kills,
		"level": level,
		"score": _compute_score({
			"duration": duration,
			"kills": kills,
			"level": level
		}),
		"date": Time.get_datetime_string_from_system()
	})

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(stats)


# ==========================
# Chargement
# ==========================
static func load_stats() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		return []
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return []

	var stats: Array = file.get_var()

	# Corrige rétroactivement les anciens runs qui n'ont pas de score
	for entry in stats:
		if not entry.has("score"):
			entry["score"] = _compute_score(entry)

	return stats


# ==========================
# Calcul du score
# ==========================
static func _compute_score(data: Dictionary) -> int:
	var duration = int(data.get("duration", 0))
	var kills    = int(data.get("kills", 0))
	var level    = int(data.get("level", 1))

	# Même formule que celle utilisée dans save_game
	return (kills * 10) + (level * 100) + (duration * 2)

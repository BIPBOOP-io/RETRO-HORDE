# res://Scripts/Managers/SaveManager.gd
extends Node
class_name SaveManager

const SAVE_PATH = "user://scores.save"

# Sauvegarde une partie
static func save_game(duration: int, kills: int, level: int) -> void:
	var stats = load_stats()
	stats.append({
		"duration": duration,
		"kills": kills,
		"level": level,
		"score": (kills * 10) + (level * 100) + (duration * 2),
		"date": Time.get_datetime_string_from_system()
	})

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(stats)
		#print("💾 Sauvegarde effectuée :", stats)
		#print("📂 Save path -> ", ProjectSettings.globalize_path(SAVE_PATH))

# Charge toutes les parties sauvegardées
static func load_stats() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		return []
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		return file.get_var()
	return []

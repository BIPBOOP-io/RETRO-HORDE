extends Node
var score_data: Dictionary = {}  # time, kills, level, etc.
var previous_scene: String = ""  # track where to return after options
var player_name: String = "Guest" # persisted player display name
var DEBUG: bool = false

# ================================
#   Global constants
# ================================

# Upgrade rarities
const RARITY_WEIGHTS = {
	"common": 60,
	"uncommon": 40,
	"rare": 25,
	"epic": 12,
	"legendary": 3
}

# XP orb values
const XP_ORBS = {
	"small": 1,
	"medium": 5,
	"large": 10
}

# Node groups
const GROUPS = {
	"player": "player",
	"enemies": "enemies",
	"hud": "hud"
}

# Global score formula
func calculate_score(data: Dictionary) -> int:
	var kills    = int(data.get("kills", 0))
	var level    = int(data.get("level", 1))
	var duration = int(data.get("duration", 0))

	return (kills * 10) + (level * 100) + (duration * 2)

func _ready() -> void:
	# Load persisted player name if available
	if has_node("/root/Settings"):
		var s = get_node("/root/Settings")
		if s.has_method("get_player_name"):
			player_name = String(s.get_player_name())

func log(msg: Variant, data: Variant = null) -> void:
	if not DEBUG:
		return
	if data == null:
		print(msg)
	else:
		print(str(msg), " ", str(data))

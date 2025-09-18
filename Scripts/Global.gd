extends Node
var score_data: Dictionary = {}  # time, kills, level, etc.

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
static func calculate_score(data: Dictionary) -> int:
	var kills    = int(data.get("kills", 0))
	var level    = int(data.get("level", 1))
	var duration = int(data.get("duration", 0))

	return (kills * 10) + (level * 100) + (duration * 2)

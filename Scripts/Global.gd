extends Node
var score_data: Dictionary = {}  # time, kills, level, etc.

# ================================
#   Constantes globales
# ================================

# Raretés des upgrades
const RARITY_WEIGHTS = {
	"common": 60,
	"rare": 25,
	"epic": 12,
	"legendary": 3
}

# Valeurs XP des orbes
const XP_ORBS = {
	"small": 1,
	"medium": 5,
	"large": 10
}

# Groupes de nodes
const GROUPS = {
	"player": "player",
	"enemies": "enemies",
	"hud": "hud"
}

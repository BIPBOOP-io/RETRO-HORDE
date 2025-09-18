extends Node
class_name UpgradeManager

# --- Définition des upgrades ---
var upgrades_data = {
	"speed":        { "title": "Speed",         "rarity": "common",    "max_level": 10 },
	"range":        { "title": "Range",         "rarity": "uncommon",  "max_level": 10 },
	"firerate":     { "title": "Fire Rate",     "rarity": "rare",      "max_level": 5 },
	"damage":       { "title": "Damage",        "rarity": "common",    "max_level": 10 },
	"extra_arrow":  { "title": "Extra Arrow",   "rarity": "epic",      "max_level": 5 },
	"multi_shot":   { "title": "Multishot",     "rarity": "legendary", "max_level": 3 },
	"regen":        { "title": "Regeneration",  "rarity": "uncommon",  "max_level": 1 },
	"xp_boost":     { "title": "XP Boost",      "rarity": "common",    "max_level": 5 },
	"knockback":    { "title": "Knockback",     "rarity": "uncommon",  "max_level": 5 },
	"vampirism":    { "title": "Vampirism",     "rarity": "epic",      "max_level": 5 },
	"shield":       { "title": "Shield",        "rarity": "epic",      "max_level": 1 },
	"pierce":       { "title": "Pierce",        "rarity": "rare",      "max_level": 5 },
	"crit":         { "title": "Critical",      "rarity": "epic",      "max_level": 5 }
}

@onready var Global = get_node("/root/Global")

const CHOICES_PER_LEVEL = 3
var upgrades_level: Dictionary = {}

func _ready():
	for key in upgrades_data.keys():
		upgrades_level[key] = 0

func get_random_upgrades() -> Array:
	var weighted_pool: Array = []
	for id in upgrades_data.keys():
		var data = upgrades_data[id]
		var current_level: int = upgrades_level[id]
		if current_level < data["max_level"]:
			var weight: int = Global.RARITY_WEIGHTS[data["rarity"]]
			for i in range(weight):
				weighted_pool.append(id)

	if weighted_pool.is_empty():
		return []

	# Assure des choix uniques en conservant le poids
	weighted_pool.shuffle()
	var unique_choices: Array = []
	var seen := {}
	for key in weighted_pool:
		if not seen.has(key):
			unique_choices.append(key)
			seen[key] = true
			if unique_choices.size() >= CHOICES_PER_LEVEL:
				break
	return unique_choices

func apply_upgrade(player: Node, choice: String):
	if not upgrades_data.has(choice): return
	if upgrades_level[choice] >= upgrades_data[choice]["max_level"]:
		return
	upgrades_level[choice] += 1

	match choice:
		"speed":
			player.speed += 20
		"range":
			player.attack_range += 30
		"firerate":
			player.attack_interval = max(0.2, player.attack_interval - 0.1)
			player.attack_timer.wait_time = player.attack_interval
		"damage":
			player.arrow_damage += 1
		"extra_arrow":
			player.arrow_count += 1
		"multi_shot":
			player.multi_shot += 1
		"regen":
			player.regen_timer.start()
		"xp_boost":
			player.xp_multiplier += 0.2
		"knockback":
			player.knockback_multiplier *= 1.5
		"vampirism":
			player.vampirism += 0.1
		"shield":
			player.has_shield = true
		"pierce":
			player.arrow_pierce += 1
		"crit":
			player.crit_chance = min(1.0, player.crit_chance + 0.1)

# Helper pour récupérer le titre d’un upgrade
func get_title(id: String) -> String:
	return upgrades_data.get(id, {}).get("title", id)

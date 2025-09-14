# res://Scripts/Upgrades/UpgradeManager.gd
extends Node
class_name UpgradeManager

# --- Définition des upgrades ---
var upgrades_data = {
	"Augmenter la vitesse de déplacement": { "rarity": "common", "max_level": 10 },
	"Augmenter la portée d’attaque": { "rarity": "common", "max_level": 10 },
	"Augmenter la cadence de tir": { "rarity": "rare", "max_level": 5 },
	"Augmenter les dégâts des flèches": { "rarity": "common", "max_level": 10 },
	"Tirer une flèche supplémentaire": { "rarity": "epic", "max_level": 5 },
	"Multiplicateur de tir": { "rarity": "legendary", "max_level": 3 },
	"Régénération lente": { "rarity": "rare", "max_level": 1 },
	"Boost d’XP": { "rarity": "common", "max_level": 5 },
	"Knockback amélioré": { "rarity": "rare", "max_level": 5 },
	"Vampirisme": { "rarity": "epic", "max_level": 5 },
	"Bouclier": { "rarity": "epic", "max_level": 1 },
	"Perforation": { "rarity": "rare", "max_level": 5 },
	"Coup critique": { "rarity": "epic", "max_level": 5 }
}


# --- Raretés ---
# Utilisation des poids de rareté globaux

# --- Import du singleton Global pour accès aux constantes globales ---
@onready var Global = get_node("/root/Global")

# --- Paramètres globaux ---
const CHOICES_PER_LEVEL = 3  # combien d’upgrades sont proposés par level-up

# --- Suivi des niveaux ---
var upgrades_level: Dictionary = {}

func _ready():
	# Initialiser tous les upgrades à 0
	for key in upgrades_data.keys():
		upgrades_level[key] = 0

# ==========================
#   Tirage d’upgrades
# ==========================
func get_random_upgrades() -> Array:
	var weighted_pool: Array = []
	for upgrade_name in upgrades_data.keys():
		var data = upgrades_data[upgrade_name]
		var current_level: int = upgrades_level[upgrade_name]

		# exclure si déjà au max
		if current_level < data.max_level:
			var weight: int = Global.RARITY_WEIGHTS[data.rarity]
			for i in range(weight):
				weighted_pool.append(upgrade_name)

	if weighted_pool.is_empty():
		return []  # plus d’upgrades dispo

	weighted_pool.shuffle()
	return weighted_pool.slice(0, CHOICES_PER_LEVEL)

# ==========================
#   Application d’un upgrade
# ==========================
func apply_upgrade(player: Node, choice: String):
	if not upgrades_data.has(choice): return

	# empêcher de dépasser max_level
	if upgrades_level[choice] >= upgrades_data[choice].max_level:
		return

	upgrades_level[choice] += 1

	match choice:
		"Augmenter la vitesse de déplacement":
			player.speed += 20
		"Augmenter la portée d’attaque":
			player.attack_range += 30
		"Augmenter la cadence de tir":
			player.attack_interval = max(0.2, player.attack_interval - 0.1)
			player.attack_timer.wait_time = player.attack_interval
		"Augmenter les dégâts des flèches":
			player.arrow_damage += 1
		"Tirer une flèche supplémentaire":
			player.arrow_count += 1
		"Multiplicateur de tir":
			player.multi_shot += 1
		"Régénération lente":
			player.regen_timer.start()
		"Boost d'XP":
			player.xp_multiplier += 0.2
		"Knockback amélioré":
			player.knockback_multiplier *= 1.5
		"Vampirisme":
			player.vampirism += 0.1
		"Bouclier":
			player.has_shield = true
		"Perforation":
			player.arrow_pierce += 1
		"Coup critique":
			player.crit_chance = min(1.0, player.crit_chance + 0.1)

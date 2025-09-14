extends Control

signal upgrade_chosen(upgrade: String)

@onready var option1: Button = $ColorRect/VBoxContainer/Option1
@onready var option2: Button = $ColorRect/VBoxContainer/Option2
@onready var option3: Button = $ColorRect/VBoxContainer/Option3

var upgrades: Array = []

func _ready():
	# Cache le menu au démarrage
	visible = false

func show_upgrades(options: Array):
	upgrades = options
	visible = true
	get_tree().paused = true
	
	# récupérer le gestionnaire d’upgrades via le joueur
	var player = get_tree().get_first_node_in_group("player")
	var upgrade_manager = player.upgrade_manager
	
	for i in range(3):
		var btn = get_node("ColorRect/VBoxContainer/Option%d" % (i+1))
		var upgrade_name = upgrades[i]
		btn.text = "%s (%d/%d)" % [
			upgrade_name,
			upgrade_manager.upgrades_level[upgrade_name],
			upgrade_manager.upgrades_data[upgrade_name].max_level
		]

		# couleur selon rareté
		var rarity = upgrade_manager.upgrades_data[upgrade_name].rarity
		match rarity:
			"common": btn.add_theme_color_override("font_color", Color(1,1,1))
			"rare": btn.add_theme_color_override("font_color", Color(0.4,0.6,1))
			"epic": btn.add_theme_color_override("font_color", Color(0.7,0.3,0.9))
			"legendary": btn.add_theme_color_override("font_color", Color(1,0.6,0))

func _on_option_pressed(index: int):
	print(">>> Bouton cliqué :", index)
	emit_signal("upgrade_chosen", upgrades[index])
	visible = false
	get_tree().paused = false

# Ces fonctions sont déclenchées par les signaux connectés dans l’éditeur
func _on_option_1_pressed(): _on_option_pressed(0)
func _on_option_2_pressed(): _on_option_pressed(1)
func _on_option_3_pressed(): _on_option_pressed(2)

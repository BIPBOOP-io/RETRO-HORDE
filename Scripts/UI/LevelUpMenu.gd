extends Control

signal upgrade_chosen(upgrade: String)

@onready var option1: Button = $ColorRect/VBoxContainer/Option1
@onready var option2: Button = $ColorRect/VBoxContainer/Option2
@onready var option3: Button = $ColorRect/VBoxContainer/Option3

var upgrades: Array = []

func _ready():
# Hide menu on start
	visible = false

func show_upgrades(options: Array):
	upgrades = options

	# If there are no options, close the menu without pausing
	if upgrades.is_empty():
		visible = false
		get_tree().paused = false
		return

	visible = true
	get_tree().paused = true

	# Retrieve the upgrade manager via the player
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var upgrade_manager = player.upgrade_manager

	var buttons: Array = [
		$ColorRect/VBoxContainer/Option1,
		$ColorRect/VBoxContainer/Option2,
		$ColorRect/VBoxContainer/Option3
	]

	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		if i < upgrades.size():
			var upgrade_id = upgrades[i]
			var data: Dictionary = upgrade_manager.upgrades_data[upgrade_id]

			btn.disabled = false
			btn.visible = true
			btn.text = "%s (%d/%d)" % [
				upgrade_manager.get_title(upgrade_id),
				upgrade_manager.upgrades_level[upgrade_id],
				int(data.get("max_level", 1))
			]

			# color based on rarity
			var rarity = str(data.get("rarity", "common"))
			match rarity:
				"common": btn.add_theme_color_override("font_color", Color(1,1,1))
				"uncommon": btn.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2)) # ✅ vert
				"rare": btn.add_theme_color_override("font_color", Color(0.4,0.6,1))
				"epic": btn.add_theme_color_override("font_color", Color(0.7,0.3,0.9))
				"legendary": btn.add_theme_color_override("font_color", Color(1,0.6,0))
		else:
			btn.disabled = true
			btn.visible = false

func _on_option_pressed(index: int):
	emit_signal("upgrade_chosen", upgrades[index])
	visible = false
	get_tree().paused = false

# These functions are triggered by signals connected in the editor
func _on_option_1_pressed(): _on_option_pressed(0)
func _on_option_2_pressed(): _on_option_pressed(1)
func _on_option_3_pressed(): _on_option_pressed(2)

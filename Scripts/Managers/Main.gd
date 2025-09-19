extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var spawner: Node2D = $EnemySpawner
@onready var hud: CanvasLayer = $Hud
@onready var pause_menu: CanvasLayer = $CanvasLayer/PauseMenu

var survival_time: int = 0
var kills: int = 0

func _ready():
	add_to_group("main")
	# Resolve player safely (instance may fail if scene had a transient parse error)
	if player == null:
		player = get_node_or_null("Player")
	if player == null:
		var p = get_tree().get_first_node_in_group("player")
		if p and p is CharacterBody2D:
			player = p
	if spawner and player:
		spawner.set_player(player)

	# Listen to player's "died" signal when available
	if player and not player.died.is_connected(on_player_died):
		player.died.connect(on_player_died)

	# Survival timer
	var survival_timer = Timer.new()
	survival_timer.wait_time = 1.0
	survival_timer.autostart = true
	survival_timer.one_shot = false
	add_child(survival_timer)
	survival_timer.timeout.connect(_on_survival_tick)

	if hud:
		hud.update_timer(survival_time)
		hud.update_kills(kills)

	# If player was not ready at _ready time, retry once on next frame
	if player == null:
		call_deferred("_retry_bind_player")

func _retry_bind_player():
	if player == null:
		var p = get_tree().get_first_node_in_group("player")
		if p and p is CharacterBody2D:
			player = p
			if spawner:
				spawner.set_player(player)
			if not player.died.is_connected(on_player_died):
				player.died.connect(on_player_died)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if _is_levelup_open():
			get_viewport().set_input_as_handled()
			return
		_toggle_pause()

func _is_levelup_open() -> bool:
	var menu = get_tree().get_first_node_in_group("levelup_menu")
	return menu != null and menu.visible

func _toggle_pause():
	# If the game is paused by another system (e.g. LevelUp menu), don't interfere
	if get_tree().paused and not pause_menu.visible:
		return
	if not pause_menu.visible:
		pause_menu.visible = true
		get_tree().paused = true
	else:
		get_tree().paused = false
		pause_menu.visible = false

# ==========================
#        TIMER
# ==========================
func _on_survival_tick():
	survival_time += 1
	if hud:
		hud.update_timer(survival_time)

# ==========================
#        KILLS
# ==========================
func register_kill():
	kills += 1
	if hud:
		hud.update_kills(kills)

func on_player_died():
	var score_data = get_score_data()
	Global.score_data = score_data

	SaveManager.save_game(
		score_data.get("duration", 0),
		score_data.get("kills", 0),
		score_data.get("level", 1)
	)

	call_deferred("_go_to_game_over")

func _go_to_game_over():
	get_tree().change_scene_to_file("res://Scenes/UI/GameOver.tscn")

# ==========================
#   End of run score data
# ==========================
func get_score_data() -> Dictionary:
	return {
		"duration": survival_time,  # use the variable directly
		"kills": kills,
		"level": player.level,
		"date": Time.get_datetime_string_from_system()
	}

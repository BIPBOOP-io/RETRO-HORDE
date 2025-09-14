extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var spawner: Node2D = $EnemySpawner
@onready var hud: CanvasLayer = $Hud

var survival_time: int = 0
var kills: int = 0

func _ready():
	spawner.set_player(player)

	# ✅ écoute l’événement "died" du player
	player.died.connect(on_player_died)

	# Timer de survie
	var survival_timer = Timer.new()
	survival_timer.wait_time = 1.0
	survival_timer.autostart = true
	survival_timer.one_shot = false
	add_child(survival_timer)
	survival_timer.timeout.connect(_on_survival_tick)

	if hud:
		hud.update_timer(survival_time)
		hud.update_kills(kills)

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

	print("💾 Sauvegarde -> ", score_data)

	SaveManager.save_game(
		score_data.get("duration", 0),
		score_data.get("kills", 0),
		score_data.get("level", 1)
	)

	call_deferred("_go_to_game_over")


func _go_to_game_over():
	get_tree().change_scene_to_file("res://Scenes/UI/GameOver.tscn")

# ==========================
#   Score de fin de partie
# ==========================
func get_score_data() -> Dictionary:
	return {
		"duration": survival_time,  # ✅ on utilise directement la variable
		"kills": kills,
		"level": player.level,
		"date": Time.get_datetime_string_from_system()
	}

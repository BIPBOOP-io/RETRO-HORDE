extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0      # initial delay between spawns
@export var spawn_margin: float = 50.0
@export var min_interval: float = 0.5        # maximum spawn speed (cap)
@export var difficulty_ramp: float = 0.98    # multiplier applied after each spawn

var player: CharacterBody2D
var timer: Timer
var main
var live_enemies: Array = []

func _ready():
	timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.one_shot = false
	add_child(timer)

	timer.timeout.connect(_spawn_enemy)

func set_player(p: CharacterBody2D):
	player = p

func set_main(m):
	main = m

func _spawn_enemy():
	if not player:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var half_w = viewport_size.x / 2
	var half_h = viewport_size.y / 2

	var side = randi() % 4
	var spawn_pos: Vector2

	match side:
		0: spawn_pos = player.global_position + Vector2(randf_range(-half_w, half_w), -half_h - spawn_margin) # top
		1: spawn_pos = player.global_position + Vector2(randf_range(-half_w, half_w), half_h + spawn_margin)  # bottom
		2: spawn_pos = player.global_position + Vector2(-half_w - spawn_margin, randf_range(-half_h, half_h)) # left
		3: spawn_pos = player.global_position + Vector2(half_w + spawn_margin, randf_range(-half_h, half_h))  # right

	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	enemy.set_player(player)
	if enemy.has_signal("killed"):
		enemy.killed.connect(Callable(self, "_on_enemy_killed"))
	enemy.tree_exited.connect(Callable(self, "_on_enemy_exited").bind(enemy))
	live_enemies.append(enemy)
	get_parent().add_child(enemy)

	# Progressive scaling: decrease interval over time
	timer.wait_time = max(min_interval, timer.wait_time * difficulty_ramp)

func _on_enemy_killed(_enemy):
	if main and main.has_method("register_kill"):
		main.register_kill()
	_on_enemy_exited(_enemy)

func _on_enemy_exited(enemy):
	var idx := live_enemies.find(enemy)
	if idx != -1:
		live_enemies.remove_at(idx)

func get_enemies() -> Array:
	return live_enemies

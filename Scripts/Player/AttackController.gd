extends Node
class_name AttackController

# Minimal skeleton to host attack logic.

var player: Node = null
var get_enemies: Callable
var attack_timer: Timer

func _ready():
	# Timer is created but not started; Player keeps current logic until migrated.
	attack_timer = Timer.new()
	attack_timer.one_shot = false
	add_child(attack_timer)

func setup(p: Node, get_enemies_fn: Callable, attack_interval: float) -> void:
	player = p
	get_enemies = get_enemies_fn
	set_attack_interval(max(0.01, attack_interval))

func set_attack_interval(seconds: float) -> void:
	if attack_timer:
		attack_timer.wait_time = seconds

func start_auto_attack() -> void:
	if attack_timer and not attack_timer.timeout.is_connected(_on_attack_tick):
		attack_timer.timeout.connect(_on_attack_tick)
	if attack_timer:
		attack_timer.start()

func stop_auto_attack() -> void:
	if attack_timer:
		attack_timer.stop()

func _on_attack_tick() -> void:
	if player == null:
		return
	var enemies: Array = []
	if get_enemies.is_valid():
		enemies = get_enemies.call()
	if enemies.is_empty():
		return

	var closest_enemy = null
	var closest_dist_sq: float = INF
	for e in enemies:
		var dist_sq = player.global_position.distance_squared_to(e.global_position)
		if dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			closest_enemy = e

	if closest_enemy and closest_dist_sq <= player.attack_range * player.attack_range:
		var dir: Vector2 = (closest_enemy.global_position - player.global_position).normalized()
		for i in range(player.multi_shot):
			var delay = i * 0.3
			fire_arrow_salvo(dir, delay)

func fire_arrow_salvo(dir: Vector2, delay: float) -> void:
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	var spread = 10.0
	var half = (player.arrow_count - 1) / 2.0
	for i in range(player.arrow_count):
		var angle_offset = (i - half) * deg_to_rad(spread)
		_spawn_arrow(dir.rotated(angle_offset))

func _spawn_arrow(direction: Vector2) -> void:
	if player.arrow_scene == null:
		return
	var arrow = player.arrow_scene.instantiate()
	arrow.global_position = player.global_position
	arrow.direction = direction
	arrow.damage = player.arrow_damage
	arrow.knockback_multiplier = player.knockback_multiplier
	arrow.pierce_left = player.arrow_pierce
	arrow.crit_chance = player.crit_chance
	arrow.crit_multiplier = player.crit_multiplier
	if player.get_parent():
		player.get_parent().add_child(arrow)

func fire_special(_dir: Vector2, _params: Dictionary = {}):
	# Placeholder for a future migration of the giant arrow logic.
	pass

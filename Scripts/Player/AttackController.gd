extends Node
class_name AttackController

# Minimal skeleton to host attack logic.

var player: Node = null
var get_enemies: Callable
var attack_timer: Timer
var special_timer: Timer
var special_ready: bool = false
var special_cooldown: float = 8.0

func _ready():
	# Timer is created but not started; Player keeps current logic until migrated.
	attack_timer = Timer.new()
	attack_timer.one_shot = false
	add_child(attack_timer)
	special_timer = Timer.new()
	special_timer.one_shot = true
	special_timer.autostart = false
	add_child(special_timer)
	if not special_timer.timeout.is_connected(_on_special_ready):
		special_timer.timeout.connect(_on_special_ready)

func setup(p: Node, get_enemies_fn: Callable, attack_interval: float, special_cd: float = 8.0) -> void:
	player = p
	get_enemies = get_enemies_fn
	set_attack_interval(max(0.01, attack_interval))
	special_cooldown = max(0.01, special_cd)
	# Start special on cooldown at match start
	special_ready = false
	if special_timer:
		special_timer.wait_time = special_cooldown
		special_timer.start()

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
	# Skip auto-attack while player input is not allowed (e.g., during HIT/CAST/DIE)
	var allow := true
	if player.has_node("PlayerStateMachine"):
		var pfsm = player.get_node("PlayerStateMachine")
		if pfsm and pfsm.has_method("allow_input"):
			allow = pfsm.allow_input()
	if not allow:
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

func _on_special_ready() -> void:
	special_ready = true

func is_special_ready() -> bool:
	return special_ready

func start_special_cooldown() -> void:
	special_ready = false
	if special_timer:
		special_timer.wait_time = special_cooldown
		special_timer.start()

func get_special_progress() -> Dictionary:
	var max_v := special_cooldown
	var elapsed: float
	if special_ready:
		elapsed = max_v
	else:
		elapsed = max_v - (special_timer.time_left if special_timer else 0.0)
	return {"elapsed": elapsed, "max": max_v, "ready": special_ready}

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

func fire_special(dir: Vector2, _params: Dictionary = {}):
	if player == null or player.arrow_scene == null:
		return

	# Instantiate a special (giant) arrow using player's special parameters
	var arrow = player.arrow_scene.instantiate()
	arrow.global_position = player.global_position
	arrow.direction = dir.normalized()

	# Scale and stats (accès direct sans has_variable)
	arrow.speed = float(arrow.speed) * player.special_speed_mult
	arrow.max_distance = player.special_max_distance
	arrow.pierce_left = player.special_pierce
	arrow.damage = int(player.arrow_damage * player.special_damage_mult)
	arrow.knockback_multiplier = player.knockback_multiplier * player.special_knockback_mult
	arrow.crit_chance = player.crit_chance
	arrow.crit_multiplier = player.crit_multiplier

	arrow.scale = Vector2.ONE * player.special_scale

	if player.get_parent():
		player.get_parent().add_child(arrow)

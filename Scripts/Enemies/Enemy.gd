extends CharacterBody2D

@export var speed: float = 60.0
@export var max_hp: int = 3
@export var damage: int = 1
@export var damage_cooldown: float = 1.0
@export var knockback_resistance: float = 1.0

# XP orb scene references
@export var xp_orb_small: PackedScene
@export var xp_orb_medium: PackedScene
@export var xp_orb_big: PackedScene

var knockback_velocity: Vector2 = Vector2.ZERO
var last_attack_time: float = 0.0

var current_hp: int
var player: CharacterBody2D
var animated_sprite: AnimatedSprite2D

func _ready():
	current_hp = max_hp
	animated_sprite = $AnimatedSprite2D
	animated_sprite.play("idle_down")
	add_to_group("enemies")

func _physics_process(delta):
	var move = Vector2.ZERO
	if player:
		var dir = (player.global_position - global_position).normalized()
		move = dir * speed
		_play_walk_animation(dir)

	velocity = move + knockback_velocity
	move_and_slide()

	# Réduction progressive du knockback
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 200 * delta)

func apply_knockback(dir: Vector2, force: float):
	var effective_force = force / knockback_resistance
	knockback_velocity = dir.normalized() * effective_force

func set_player(p: CharacterBody2D):
	player = p

func take_damage(amount: int):
	current_hp -= amount
	if current_hp <= 0:
		die()

func die():
	if xp_orb_small or xp_orb_medium or xp_orb_big:
		var spawn_pos = global_position
		call_deferred("_spawn_xp_orb", spawn_pos)

	# Inform Main about a kill
	var main = get_tree().get_first_node_in_group("main")
	if main and main.has_method("register_kill"):
		main.register_kill()

	call_deferred("queue_free")

# Time-based scaling of XP orb sizes

func _choose_orb_scene(desired: String) -> PackedScene:
	if desired == "big":
		for s in [xp_orb_big, xp_orb_medium, xp_orb_small]:
			if s: return s
	elif desired == "medium":
		for s in [xp_orb_medium, xp_orb_small, xp_orb_big]:
			if s: return s
	else:
		for s in [xp_orb_small, xp_orb_medium, xp_orb_big]:
			if s: return s
	return null

func _spawn_xp_orb(pos: Vector2):
	var elapsed = Time.get_ticks_msec() / 1000.0  # elapsed time in seconds
	var orb: Area2D
	var roll = randf()

	# Evolving probabilities
	var medium_chance = clamp(elapsed / 120.0, 0.0, 0.25)  # up to 25% in 2 minutes
	var big_chance = clamp(elapsed / 300.0, 0.0, 0.15)     # up to 15% in 5 minutes
	var small_chance = 1.0 - medium_chance - big_chance

	var desired := "small"
	if roll < small_chance:
		desired = "small"
	elif roll < small_chance + medium_chance:
		desired = "medium"
	else:
		desired = "big"

	var scene: PackedScene = _choose_orb_scene(desired)
	if scene == null:
		return
	orb = scene.instantiate()

	orb.global_position = pos
	get_parent().add_child(orb)

func _play_walk_animation(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			animated_sprite.play("walk_right")
		else:
			animated_sprite.play("walk_left")
	else:
		if dir.y > 0:
			animated_sprite.play("walk_down")
		else:
			animated_sprite.play("walk_up")

func _on_Hitbox_body_entered(body: Node):
	if body.is_in_group("player") and body.has_method("take_damage"):
		var now = Time.get_ticks_msec() / 1000.0
		if now - last_attack_time >= damage_cooldown:
			body.take_damage(damage)
			last_attack_time = now

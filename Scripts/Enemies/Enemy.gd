extends CharacterBody2D

signal killed(enemy)

@export var speed: float = 60.0
@export var max_hp: int = 3
@export var damage: int = 1
@export var damage_cooldown: float = 1.0 # seconds between two damages to the player
@export var knockback_resistance: float = 1.0

# Animation timing (tweak per enemy type as needed)
@export var attack_anim_duration: float = 0.25
@export var hit_anim_duration: float = 0.15
@export var die_anim_duration: float = 0.4

# Attack trigger and hitbox config
@export var attack_trigger_distance: float = 28.0
@export var attack_windup: float = 0.12
@export var attack_active: float = 0.10
@export var attack_recovery: float = 0.2
@export var attack_hitbox_offset: float = 16.0

# XP orb scene references
@export var xp_orb_small: PackedScene
@export var xp_orb_medium: PackedScene
@export var xp_orb_big: PackedScene

var knockback_velocity: Vector2 = Vector2.ZERO
var last_attack_time: float = 0.0

enum State { WALK, ATTACK, HIT, DIE }
var state: int = State.WALK
var last_dir: Vector2 = Vector2.DOWN
var last_dir_str: String = "down"

var current_hp: int
var player: CharacterBody2D
var animated_sprite: AnimatedSprite2D
var attack_fx: AnimatedSprite2D
var attack_area: Area2D
var attack_shape: CollisionShape2D
var _attack_has_hit: bool = false

func _ready():
	current_hp = max_hp
	animated_sprite = $AnimatedSprite2D
	attack_fx = $AttackFX if has_node("AttackFX") else null
	attack_area = $AttackArea if has_node("AttackArea") else null
	attack_shape = $AttackArea/CollisionShape2D if has_node("AttackArea/CollisionShape2D") else null
	if attack_area:
		if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
			attack_area.body_entered.connect(_on_attack_area_body_entered)
	# Allow first attack immediately if in range (no initial cooldown wait)
	last_attack_time = -damage_cooldown
	if animated_sprite and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation("idle_down"):
		animated_sprite.play("idle_down")
	add_to_group("enemies")

func _physics_process(delta):
	var move = Vector2.ZERO
	if player and state == State.WALK:
		var dir = (player.global_position - global_position)
		if dir.length() > 0.001:
			last_dir = dir.normalized()
			last_dir_str = _dir_to_str(last_dir)
		# trigger attack if player is close enough and cooldown elapsed
		var now = Time.get_ticks_msec() / 1000.0
		if dir.length() <= attack_trigger_distance and (now - last_attack_time) >= damage_cooldown:
			last_attack_time = now
			_start_attack()
		else:
			move = last_dir.normalized() * speed
			_play_walk_animation(last_dir)

	velocity = move + knockback_velocity
	move_and_slide()

	# Gradual reduction of knockback
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 200 * delta)

func apply_knockback(dir: Vector2, force: float):
	var effective_force = force / max(0.001, knockback_resistance)
	knockback_velocity = dir.normalized() * effective_force

func set_player(p: CharacterBody2D):
	player = p

func take_damage(amount: int):
	if state == State.DIE:
		return
	current_hp -= amount
	if current_hp <= 0:
		_start_die()
	else:
		_start_hit()

func die():
	# kept for backward compatibility; now calls _start_die
	_start_die()

func _start_die() -> void:
	if state == State.DIE:
		return
	state = State.DIE
	_play_dir_anim("die")
	# disable collisions (deferred to avoid flushing query errors)
	var cs: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
	if cs:
		cs.set_deferred("disabled", true)
	var hb: Area2D = $Hitbox if has_node("Hitbox") else null
	if hb:
		hb.set_deferred("monitoring", false)
		hb.set_deferred("monitorable", false)
	await get_tree().create_timer(die_anim_duration).timeout
	if xp_orb_small or xp_orb_medium or xp_orb_big:
		var spawn_pos = global_position
		_spawn_xp_orb(spawn_pos)
	emit_signal("killed", self)
	queue_free()

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
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0 and animated_sprite.sprite_frames.has_animation("walk_right"):
			animated_sprite.play("walk_right")
		elif animated_sprite.sprite_frames.has_animation("walk_left"):
			animated_sprite.play("walk_left")
	else:
		if dir.y > 0 and animated_sprite.sprite_frames.has_animation("walk_down"):
			animated_sprite.play("walk_down")
		elif animated_sprite.sprite_frames.has_animation("walk_up"):
			animated_sprite.play("walk_up")

func _dir_to_str(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "down" if dir.y > 0 else "up"

func _play_dir_anim(prefix: String) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var anim_name := "%s_%s" % [prefix, last_dir_str]
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	elif animated_sprite.sprite_frames.has_animation(prefix):
		animated_sprite.play(prefix)

func _on_Hitbox_body_entered(body: Node):
	if state == State.DIE:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		var now = Time.get_ticks_msec() / 1000.0
		if now - last_attack_time >= damage_cooldown:
			last_attack_time = now
			var dir = (body.global_position - global_position)
			if dir.length() > 0.001:
				last_dir = dir.normalized()
				last_dir_str = _dir_to_str(last_dir)
			_start_attack()

func _start_attack() -> void:
	if state == State.DIE:
		return
	state = State.ATTACK
	_play_dir_anim("attack")
	if attack_fx:
		attack_fx.visible = true
		var fx_anim := "attackfx_%s" % last_dir_str
		if attack_fx.sprite_frames and attack_fx.sprite_frames.has_animation(fx_anim):
			attack_fx.play(fx_anim)
		elif attack_fx.sprite_frames and attack_fx.sprite_frames.has_animation("attackfx"):
			attack_fx.play("attackfx")
	_attack_has_hit = false
	# Windup
	await get_tree().create_timer(attack_windup).timeout
	# Activate hitbox during active frames
	if attack_area:
		_position_attack_area()
		attack_area.set_deferred("monitoring", true)
		attack_area.set_deferred("monitorable", true)
	await get_tree().create_timer(attack_active).timeout
	if attack_area:
		attack_area.set_deferred("monitoring", false)
		attack_area.set_deferred("monitorable", false)
	# Recovery
	await get_tree().create_timer(attack_recovery).timeout
	if attack_fx:
		attack_fx.visible = false
	if state != State.DIE:
		state = State.WALK

func _start_hit() -> void:
	if state == State.DIE:
		return
	state = State.HIT
	_play_dir_anim("hit")
	await get_tree().create_timer(hit_anim_duration).timeout
	if state != State.DIE:
		state = State.WALK

func _position_attack_area() -> void:
	if not attack_area:
		return
	var offs := attack_hitbox_offset
	match last_dir_str:
		"left": attack_area.position = Vector2(-offs, 0)
		"right": attack_area.position = Vector2(offs, 0)
		"up": attack_area.position = Vector2(0, -offs)
		_: attack_area.position = Vector2(0, offs)

func _on_attack_area_body_entered(body: Node) -> void:
	if state != State.ATTACK or _attack_has_hit:
		return
	if body and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		_attack_has_hit = true

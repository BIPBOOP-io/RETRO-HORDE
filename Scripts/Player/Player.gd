extends CharacterBody2D

signal died

# --- Movement & Combat ---
@export var speed: float = 100.0
@export var attack_interval: float = 1.0
@export var attack_range: float = 100.0
@export var arrow_scene: PackedScene
@export var arrow_damage: int = 1

# Sprinting
@export var sprint_multiplier: float = 1.5  # applies to move speed and anim speed
var is_sprinting: bool = false

# Stamina
@export var max_stamina: float = 100.0
@export var stamina: float = 100.0
@export var stamina_drain_per_sec: float = 20.0
@export var stamina_regen_per_sec: float = 12.0
@export var stamina_ready_fraction: float = 0.25
var stamina_locked: bool = false  # becomes true only if stamina reached 0

# --- Stats & XP ---
@export var max_health: int = 10
@export var health: int = 10
@export var xp_to_next_level: int = 5

@export var heal_particles_scene: PackedScene
@export var levelup_particles_scene: PackedScene

var level: int = 1
var xp: int = 0

# --- Upgrades (runtime values modified by UpgradeManager) ---
var arrow_count: int = 1
var multi_shot: int = 1
var xp_multiplier: float = 1.0
var knockback_multiplier: float = 1.0
var vampirism: float = 0.0
var has_shield: bool = false
var arrow_pierce: int = 0
var crit_chance: float = 0.0
var crit_multiplier: float = 2.0

# --- Special ability (Giant Arrow) ---
@export var special_cooldown: float = 8.0
@export var special_arrow_scene: PackedScene
@export var special_scale: float = 2.0
@export var special_damage_mult: float = 4.0
@export var special_speed_mult: float = 1.2
@export var special_max_distance: float = 5000.0
@export var special_pierce: int = -1
@export var special_knockback_mult: float = 3.0
var special_ready: bool = false
var special_timer: Timer

# --- References ---
var animated_sprite: AnimatedSprite2D
var attack_timer: Timer
var hud: Node
var regen_timer: Timer
@onready var upgrade_manager: UpgradeManager = preload("res://Scripts/Managers/UpgradeManager.gd").new()
@onready var health_bar_2d: Node2D = $HealthBar2D
@onready var special_bar_2d: Node2D = $SpecialBar2D
@onready var stamina_bar_2d: Node2D = $StaminaBar2D

func _ready():
	animated_sprite = $AnimatedSprite2D
	animated_sprite.play("idle_down")
	add_to_group("player")

	# Add the UpgradeManager to the scene
	add_child(upgrade_manager)

	hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_level(level)
		hud.update_xp(xp, xp_to_next_level)
		hud.update_health(health, max_health)
		if hud.has_method("update_stamina"):
			hud.update_stamina(stamina, max_stamina)
			if hud.has_method("update_special"):
				hud.update_special(0.0, special_cooldown)

	# Init in-world bars
	if health_bar_2d and health_bar_2d.has_method("set_values"):
		health_bar_2d.set_values(health, max_health)
	if stamina_bar_2d and stamina_bar_2d.has_method("set_values"):
		stamina_bar_2d.set_values(stamina, max_stamina)
	if special_bar_2d and special_bar_2d.has_method("set_values"):
		special_bar_2d.set_values(0.0, special_cooldown)

	# Auto-attack timer
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_interval
	attack_timer.autostart = true
	attack_timer.one_shot = false
	add_child(attack_timer)
	attack_timer.timeout.connect(_auto_attack)

	# Slow regeneration timer
	regen_timer = Timer.new()
	regen_timer.wait_time = 2.0
	regen_timer.autostart = false
	regen_timer.one_shot = false
	regen_timer.timeout.connect(_on_regen_tick)
	add_child(regen_timer)

	# Special ability cooldown timer
	special_timer = Timer.new()
	special_timer.wait_time = special_cooldown
	special_timer.one_shot = true
	special_timer.autostart = false
	special_timer.timeout.connect(_on_special_ready)
	add_child(special_timer)
	# Start special on cooldown at match start
	special_ready = false
	special_timer.start()

# ==========================
#       MOVEMENT
# ==========================
func _physics_process(delta):
	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	is_sprinting = Input.is_action_pressed("sprint") and input_vector != Vector2.ZERO and _can_sprint()
	var current_speed = speed * (sprint_multiplier if is_sprinting else 1.0)
	velocity = input_vector * current_speed
	move_and_slide()

	if input_vector == Vector2.ZERO:
		animated_sprite.speed_scale = 1.0
		_play_idle_animation()
	else:
		animated_sprite.speed_scale = sprint_multiplier if is_sprinting else 1.0
		_play_walk_animation(input_vector)

	_update_stamina(delta)
	_update_special_bar()

func _update_stamina(delta: float) -> void:
	# Drain while sprinting, regen otherwise
	if not has_node("/root/Settings"): # safe-guard
		return
	if is_sprinting:
		var prev := stamina
		stamina = max(0.0, stamina - stamina_drain_per_sec * delta)
		if stamina <= 0.0 and prev > 0.0:
			stamina_locked = true
	else:
		stamina = min(max_stamina, stamina + stamina_regen_per_sec * delta)

	var thr := max_stamina * stamina_ready_fraction
	if stamina_locked and stamina >= thr:
		stamina_locked = false

	if hud and hud.has_method("update_stamina"):
		hud.update_stamina(stamina, max_stamina)

	if stamina_bar_2d and stamina_bar_2d.has_method("set_values"):
		# Orange only while recovering below threshold after full depletion
		if (not is_sprinting) and stamina_locked and stamina < thr:
			stamina_bar_2d.fill_color = Color(1, 0.5, 0, 1)
		else:
			stamina_bar_2d.fill_color = Color(1, 0.85, 0, 1)
		stamina_bar_2d.set_values(stamina, max_stamina)

func _update_special_bar() -> void:
	var elapsed_val: float
	var max_val := special_cooldown
	if special_ready:
		elapsed_val = max_val
	else:
		elapsed_val = max_val - special_timer.time_left
	if hud and hud.has_method("update_special"):
		hud.update_special(elapsed_val, max_val)
	if special_bar_2d and special_bar_2d.has_method("set_values"):
		# Color cue: slightly lighter purple when ready
		if special_ready:
			special_bar_2d.fill_color = Color(0.68, 0.45, 0.98, 1.0)
		else:
			special_bar_2d.fill_color = Color(0.58, 0.3, 0.9, 1.0)
		special_bar_2d.set_values(elapsed_val, max_val)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("special"):
		_try_fire_special()

func _try_fire_special():
	if not special_ready:
		return
	var dir = _get_best_target_direction()
	if dir == Vector2.ZERO:
		return
	_fire_giant_arrow(dir)
	special_ready = false
	special_timer.wait_time = special_cooldown
	special_timer.start()

func _on_special_ready():
	special_ready = true

func _get_best_target_direction() -> Vector2:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return Vector2.ZERO
	var closest = null
	var closest_dist_sq: float = INF
	for e in enemies:
		var d2 = global_position.distance_squared_to(e.global_position)
		if d2 < closest_dist_sq:
			closest_dist_sq = d2
			closest = e
	if closest:
		return (closest.global_position - global_position).normalized()
	return Vector2.ZERO

func _fire_giant_arrow(dir: Vector2):
	var scene: PackedScene = special_arrow_scene if special_arrow_scene else arrow_scene
	if scene == null:
		return
	var arrow = scene.instantiate()
	arrow.global_position = global_position
	arrow.direction = dir
	arrow.damage = int(arrow_damage * special_damage_mult)
	arrow.speed = float(arrow.speed) * special_speed_mult
	arrow.max_distance = special_max_distance
	arrow.pierce_left = special_pierce
	arrow.knockback_multiplier = knockback_multiplier * special_knockback_mult
	arrow.crit_chance = crit_chance
	arrow.crit_multiplier = crit_multiplier
	arrow.scale = Vector2.ONE * special_scale
	get_parent().add_child(arrow)

func _can_sprint() -> bool:
	# Sprinting is blocked only if stamina was totally depleted,
	# and only until it recovers above the threshold.
	if stamina <= 0.0:
		return false
	if stamina_locked and stamina < (max_stamina * stamina_ready_fraction):
		return false
	return true

func _play_walk_animation(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0: animated_sprite.play("walk_right")
		else: animated_sprite.play("walk_left")
	else:
		if dir.y > 0: animated_sprite.play("walk_down")
		else: animated_sprite.play("walk_up")

func _play_idle_animation():
	var current_anim = animated_sprite.animation
	if "walk" in current_anim:
		animated_sprite.play(current_anim.replace("walk", "idle"))

# ==========================
#       AUTO-ATTACK
# ==========================
func _auto_attack():
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty(): return

	var closest_enemy = null
	var closest_dist_sq: float = INF
	for e in enemies:
		var dist_sq = global_position.distance_squared_to(e.global_position)
		if dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			closest_enemy = e

	if closest_enemy and closest_dist_sq <= attack_range * attack_range:
		var dir = (closest_enemy.global_position - global_position).normalized()
		for i in range(multi_shot):
			var delay = i * 0.3
			_fire_arrow_salvo(dir, delay)

func _fire_arrow_salvo(dir: Vector2, delay: float):
	if delay > 0: await get_tree().create_timer(delay).timeout

	var spread = 10.0
	var half = (arrow_count - 1) / 2.0
	for i in range(arrow_count):
		var angle_offset = (i - half) * deg_to_rad(spread)
		_spawn_arrow(dir.rotated(angle_offset))

func _spawn_arrow(direction: Vector2):
	var arrow = arrow_scene.instantiate()
	arrow.global_position = global_position
	arrow.direction = direction
	arrow.damage = arrow_damage
	arrow.knockback_multiplier = knockback_multiplier
	arrow.pierce_left = arrow_pierce
	arrow.crit_chance = crit_chance
	arrow.crit_multiplier = crit_multiplier
	get_parent().add_child(arrow)

# ==========================
#         XP & LEVEL
# ==========================
func gain_xp(amount: int):
	xp += int(amount * xp_multiplier)
	if hud: hud.update_xp(xp, xp_to_next_level)
	if xp >= xp_to_next_level: level_up()

func level_up():
	level += 1
	xp -= xp_to_next_level
	xp_to_next_level = int(xp_to_next_level * 1.5)

	if hud:
		hud.update_level(level)
		hud.update_xp(xp, xp_to_next_level)

	var upgrades = upgrade_manager.get_random_upgrades()
	var menu = get_tree().get_first_node_in_group("levelup_menu")
	if menu:
		if not menu.upgrade_chosen.is_connected(_apply_upgrade):
			menu.upgrade_chosen.connect(_apply_upgrade)
		menu.show_upgrades(upgrades)
	flash_gold()

func _apply_upgrade(choice: String):
	upgrade_manager.apply_upgrade(self, choice)
	flash_gold()
	if hud and hud.has_method("show_upgrade_toast"):
		hud.show_upgrade_toast(upgrade_manager.get_title(choice))

# ==========================
#       HEALTH & DAMAGE
# ==========================
func take_damage(amount: int):
	if has_shield:
		has_shield = false
		return

	health -= amount
	if hud: hud.update_health(health, max_health)
	if health_bar_2d and health_bar_2d.has_method("set_values"):
		health_bar_2d.set_values(health, max_health)
	flash_red()
	shake_camera()
	if health <= 0: die()

func heal_from_vampirism(damage_dealt: int):
	if vampirism > 0.0 and health < max_health:  # only if not at full health
		var heal_amount = max(1, round(damage_dealt * vampirism))
		var new_health = min(max_health, health + heal_amount)

		if new_health > health:  # only if it actually heals
			health = new_health
			if hud: hud.update_health(health, max_health)
			if health_bar_2d and health_bar_2d.has_method("set_values"):
				health_bar_2d.set_values(health, max_health)
			flash_green()

func _on_regen_tick():
	if health < max_health:  # block regen if already at full health
		health += 1
		if hud: hud.update_health(health, max_health)
		if health_bar_2d and health_bar_2d.has_method("set_values"):
			health_bar_2d.set_values(health, max_health)
		flash_green()

# ==========================
#   VISUAL FEEDBACK
# ==========================
func flash_red():
	modulate = Color(1, 0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.2)

func flash_green():
	modulate = Color(0.3, 1, 0.3)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.2)

func flash_gold():
	modulate = Color(1, 0.85, 0.2)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.4)

func shake_camera():
	var cam = get_viewport().get_camera_2d()
	if cam:
		var tween = create_tween()
		tween.tween_property(cam, "offset", Vector2(10, 0), 0.05).as_relative()
		tween.tween_property(cam, "offset", Vector2(-20, 0), 0.1).as_relative()
		tween.tween_property(cam, "offset", Vector2(10, 0), 0.05).as_relative()
		tween.tween_property(cam, "offset", Vector2(0, 0), 0.05)

func spawn_particles(particles_scene: PackedScene):
	if particles_scene:
		var p = particles_scene.instantiate()
		p.global_position = global_position
		get_parent().add_child(p)
		p.emitting = true

func die():
	emit_signal("died")  # notify Main that the player died
	queue_free()         # optionally free the Player

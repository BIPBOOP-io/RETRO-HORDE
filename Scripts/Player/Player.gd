extends CharacterBody2D

signal died

# --- Mouvements & Combat ---
@export var speed: float = 100.0
@export var attack_interval: float = 1.0
@export var attack_range: float = 100.0
@export var arrow_scene: PackedScene
@export var arrow_damage: int = 1

# --- Stats & XP ---
@export var max_health: int = 10
@export var health: int = 10
@export var xp_to_next_level: int = 5

@export var heal_particles_scene: PackedScene
@export var levelup_particles_scene: PackedScene

var level: int = 1
var xp: int = 0

# --- Upgrades (valeurs dynamiques modifiées par UpgradeManager) ---
var arrow_count: int = 1
var multi_shot: int = 1
var xp_multiplier: float = 1.0
var knockback_multiplier: float = 1.0
var vampirism: float = 0.0
var has_shield: bool = false
var arrow_pierce: int = 0
var crit_chance: float = 0.0
var crit_multiplier: float = 2.0

# --- Références ---
var animated_sprite: AnimatedSprite2D
var attack_timer: Timer
var hud: Node
var regen_timer: Timer
@onready var upgrade_manager: UpgradeManager = preload("res://Scripts/Managers/UpgradeManager.gd").new()

func _ready():
	animated_sprite = $AnimatedSprite2D
	animated_sprite.play("idle_down")
	add_to_group("player")

	# Ajouter le gestionnaire d’upgrades à la scène
	add_child(upgrade_manager)

	hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_level(level)
		hud.update_xp(xp, xp_to_next_level)
		hud.update_health(health, max_health)

	# Timer auto-attaque
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_interval
	attack_timer.autostart = true
	attack_timer.one_shot = false
	add_child(attack_timer)
	attack_timer.timeout.connect(_auto_attack)

	# Timer régénération lente
	regen_timer = Timer.new()
	regen_timer.wait_time = 2.0
	regen_timer.autostart = false
	regen_timer.one_shot = false
	regen_timer.timeout.connect(_on_regen_tick)
	add_child(regen_timer)

# ==========================
#       Déplacements
# ==========================
func _physics_process(_delta):
	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	velocity = input_vector * speed
	move_and_slide()

	if input_vector == Vector2.ZERO:
		_play_idle_animation()
	else:
		_play_walk_animation(input_vector)

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
#       Auto-attaque
# ==========================
func _auto_attack():
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty(): return

	var closest_enemy = null
	var closest_dist = INF
	for e in enemies:
		var dist = global_position.distance_to(e.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_enemy = e

	if closest_enemy and closest_dist <= attack_range:
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

# ==========================
#       VIE & DÉGÂTS
# ==========================
func take_damage(amount: int):
	if has_shield:
		has_shield = false
		print("Bouclier absorbé !")
		return
	health -= amount
	if hud: hud.update_health(health, max_health)
	flash_red()
	shake_camera()
	if health <= 0: die()

func heal_from_vampirism(damage_dealt: int):
	if vampirism > 0.0 and health < max_health:  # ✅ uniquement si pas full vie
		var heal_amount = max(1, round(damage_dealt * vampirism))
		var new_health = min(max_health, health + heal_amount)

		if new_health > health:  # ✅ seulement si ça soigne vraiment
			health = new_health
			if hud: hud.update_health(health, max_health)
			flash_green()

func _on_regen_tick():
	if health < max_health:  # ✅ bloque la regen si déjà full vie
		health += 1
		if hud: hud.update_health(health, max_health)
		flash_green()

# ==========================
#   FEEDBACK VISUELS
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
	emit_signal("died")  # ✅ on prévient le Main que le joueur est mort
	queue_free()         # ✅ optionnel : détruit le Player

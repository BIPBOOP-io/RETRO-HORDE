extends CharacterBody2D

signal died

# --- States & Animations ---
@onready var fsm: PlayerStateMachine = $PlayerStateMachine if has_node("PlayerStateMachine") else null

# Tunables for non-loop animations
@export var hit_anim_duration: float = 0.15
@export var die_anim_duration: float = 0.40
@export var cast_anim_duration: float = 0.25

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
var _has_shield: bool = false
var has_shield: bool:
	set = set_has_shield,
	get = get_has_shield
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

# --- References ---
var animated_sprite: AnimatedSprite2D
var hud: Node
var regen_timer: Timer
@onready var upgrade_manager: UpgradeManager = preload("res://Scripts/Managers/UpgradeManager.gd").new()
var enemy_provider: Node = null
@onready var health_bar_2d: Node2D = $HealthBar2D
@onready var special_bar_2d: Node2D = $SpecialBar2D
@onready var stamina_bar_2d: Node2D = $StaminaBar2D
@onready var attack_ctrl: AttackController = $AttackController if has_node("AttackController") else null
@onready var health_comp: HealthComponent = $HealthComponent if has_node("HealthComponent") else null
@onready var feedback: Feedback = $Feedback if has_node("Feedback") else null
@onready var stamina_comp: StaminaComponent = $StaminaComponent if has_node("StaminaComponent") else null
var knockback_velocity: Vector2 = Vector2.ZERO

func _ready():
	animated_sprite = $AnimatedSprite2D
	animated_sprite.play("idle_down")
	add_to_group("player")

	# Ensure FSM exists and is configured
	if fsm == null:
		fsm = PlayerStateMachine.new()
		add_child(fsm)
	fsm.setup(animated_sprite)

	# Add the UpgradeManager to the scene
	add_child(upgrade_manager)

	hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_level(level)
		hud.update_xp(xp, xp_to_next_level)
		hud.update_health(health, max_health)


	# Init in-world bars
	if health_bar_2d and health_bar_2d.has_method("set_values"):
		health_bar_2d.set_values(health, max_health)
	if special_bar_2d and special_bar_2d.has_method("set_values"):
		special_bar_2d.set_values(0.0, special_cooldown)

	# Ensure AttackController exists
	if attack_ctrl == null:
		attack_ctrl = AttackController.new()
		add_child(attack_ctrl)
	# Setup and start auto attack
	if attack_ctrl:
		attack_ctrl.setup(self, Callable(self, "_get_enemies"), attack_interval, special_cooldown)
		attack_ctrl.start_auto_attack()

	# Slow regeneration timer (fallback if no health component)
	if health_comp == null:
		regen_timer = Timer.new()
		regen_timer.wait_time = 2.0
		regen_timer.autostart = false
		regen_timer.one_shot = false
		regen_timer.timeout.connect(_on_regen_tick)
		add_child(regen_timer)

	# Optional controllers
	if health_comp:
		health_comp.setup(self, hud, 2.0)
	if feedback:
		feedback.setup(self)
	# Ensure StaminaComponent exists and is configured
	if stamina_comp == null:
		stamina_comp = StaminaComponent.new()
		add_child(stamina_comp)
	if stamina_comp:
		stamina_comp.setup(self, hud, stamina_bar_2d, {
			"max_value": max_stamina,
			"value": stamina,
			"drain": stamina_drain_per_sec,
			"regen": stamina_regen_per_sec,
			"ready_fraction": stamina_ready_fraction,
		})

	# Ensure shield tint reflects initial state (usually false)
	set_has_shield(has_shield)

# ==========================
#       MOVEMENT
# ==========================
func _physics_process(delta):
	# Movement is only player-driven in MOVE/IDLE. Other states limit to knockback glide.
	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	var allow_input := (fsm != null and fsm.allow_input())
	is_sprinting = allow_input and Input.is_action_pressed("sprint") and input_vector != Vector2.ZERO and (stamina_comp == null or stamina_comp.can_sprint())
	var current_speed = speed * (sprint_multiplier if is_sprinting else 1.0)
	var move_vec: Vector2 = (input_vector * current_speed) if allow_input else Vector2.ZERO
	velocity = move_vec + knockback_velocity
	move_and_slide()
	# Gradually reduce knockback
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 400 * delta)

	# Update facing and locomotion animations only in locomotion states
	if allow_input:
		if input_vector == Vector2.ZERO:
			animated_sprite.speed_scale = 1.0
			if fsm: fsm.play_idle()
		else:
			animated_sprite.speed_scale = sprint_multiplier if is_sprinting else 1.0
			if fsm:
				fsm.update_direction(input_vector)
				fsm.play_walk(input_vector)

	if stamina_comp:
		stamina_comp.tick(delta, is_sprinting)
	_update_special_bar()

func _update_special_bar() -> void:
	if attack_ctrl == null:
		return
	var prog: Dictionary = attack_ctrl.get_special_progress()
	var elapsed_val: float = float(prog.get("elapsed", 0.0))
	var max_val: float = float(prog.get("max", special_cooldown))
	var is_ready: bool = bool(prog.get("ready", false))
	if hud and hud.has_method("update_special"):
		hud.update_special(elapsed_val, max_val)
	if special_bar_2d and special_bar_2d.has_method("set_values"):
		# Color cue: slightly lighter purple when ready
		special_bar_2d.fill_color = Color(0.68, 0.45, 0.98, 1.0) if is_ready else Color(0.58, 0.3, 0.9, 1.0)
		special_bar_2d.set_values(elapsed_val, max_val)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("special"):
		_try_fire_special()

func _try_fire_special():
	if attack_ctrl == null or not attack_ctrl.is_special_ready():
		return
	var dir = _get_best_target_direction()
	if dir == Vector2.ZERO:
		return
	# Enter CAST state: play cast then fire the special
	_start_cast(dir)

func _get_best_target_direction() -> Vector2:
	var enemies = _get_enemies()
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
	if attack_ctrl:
		attack_ctrl.fire_special(dir)
		return

# ==========================
#       STATE HELPERS
# ==========================

func start_hit() -> void:
	if fsm:
		fsm.play_hit(hit_anim_duration)

func _start_cast(dir: Vector2) -> void:
	if fsm and (fsm.in_state(PlayerStateMachine.State.DIE) or fsm.in_state(PlayerStateMachine.State.FALLING)):
		return
	# consume special immediately via controller
	if attack_ctrl:
		attack_ctrl.start_special_cooldown()
	# face cast direction then play cast using FSM
	if fsm:
		fsm.update_direction(dir)
		var cb := Callable(self, "_after_cast").bind(dir)
		await fsm.play_cast(cast_anim_duration, cb)

func _after_cast(dir: Vector2) -> void:
	if fsm and (fsm.in_state(PlayerStateMachine.State.DIE) or fsm.in_state(PlayerStateMachine.State.FALLING)):
		return
	_fire_giant_arrow(dir)

func _start_fall() -> void:
	# Placeholder: falling state reserved for future holes/transition mechanic
	if fsm:
		# Use cast of enum value without animation for now
		fsm.state = PlayerStateMachine.State.FALLING


## Sprint gating handled by StaminaComponent

## Animations handled by FSM

	# (auto-attack handled by AttackController)

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
	# Removed upgrade orange flash; reserved color used for shield tint

func _apply_upgrade(choice: String):
	upgrade_manager.apply_upgrade(self, choice)
	# Removed upgrade orange flash; reserved color used for shield tint
	if hud and hud.has_method("show_upgrade_toast"):
		hud.show_upgrade_toast(upgrade_manager.get_title(choice))

# ==========================
#       HEALTH & DAMAGE
# ==========================
func take_damage(amount: int):
	if health_comp:
		# Let component handle stats/UI (it will also trigger hit state/feedback)
		health_comp.damage(amount)
		return
	if has_shield:
		has_shield = false
		return
	# Local damage path
	# Play hit state first (brief) when non-lethal
	var lethal := (health - amount) <= 0
	if not lethal:
		start_hit()
	health -= amount
	if hud: hud.update_health(health, max_health)
	if health_bar_2d and health_bar_2d.has_method("set_values"):
		health_bar_2d.set_values(health, max_health)
	if feedback:
		feedback.flash_red()
		feedback.shake_camera()
	if health <= 0: die()

func apply_knockback(dir: Vector2, force: float) -> void:
	if dir.length() > 0.001 and force > 0.0:
		knockback_velocity = dir.normalized() * force

func heal_from_vampirism(damage_dealt: int):
	if health_comp:
		health_comp.apply_vampirism(damage_dealt)
		return
	if vampirism > 0.0 and health < max_health:  # only if not at full health
		var heal_amount = max(1, round(damage_dealt * vampirism))
		var new_health = min(max_health, health + heal_amount)
		if new_health > health:  # only if it actually heals
			health = new_health
			if hud: hud.update_health(health, max_health)
			if health_bar_2d and health_bar_2d.has_method("set_values"):
				health_bar_2d.set_values(health, max_health)
			var settings := get_node_or_null("/root/Settings")
			if settings and settings.has_method("is_heal_feedback_on") and settings.is_heal_feedback_on():
				if feedback:
					feedback.flash_green()

func _on_regen_tick():
	if health_comp:
		health_comp._on_regen_tick()
		return
	if health < max_health:  # block regen if already at full health
		health += 1
		if hud: hud.update_health(health, max_health)
		if health_bar_2d and health_bar_2d.has_method("set_values"):
			health_bar_2d.set_values(health, max_health)
		var settings := get_node_or_null("/root/Settings")
		if settings and settings.has_method("is_heal_feedback_on") and settings.is_heal_feedback_on():
			if feedback:
				feedback.flash_green()

func spawn_particles(particles_scene: PackedScene):
	if particles_scene:
		var p = particles_scene.instantiate()
		p.global_position = global_position
		get_parent().add_child(p)
		p.emitting = true

func set_has_shield(on: bool) -> void:
	_has_shield = on
	if feedback:
		if on:
			var c: Color = Color(1, 0.5, 0, 1)
			var settings := get_node_or_null("/root/Settings")
			if settings and settings.has_method("get_shield_tint"):
				c = settings.get_shield_tint()
			feedback.set_tint(c)
		else:
			feedback.clear_tint()

func get_has_shield() -> bool:
	return _has_shield

func die():
	if fsm:
		await fsm.play_die(die_anim_duration, Callable(self, "_after_die"))

func _after_die():
	emit_signal("died")
	queue_free()
func set_enemy_provider(p: Node) -> void:
	enemy_provider = p

func _get_enemies() -> Array:
	if enemy_provider and enemy_provider.has_method("get_enemies"):
		return enemy_provider.get_enemies()
	return get_tree().get_nodes_in_group("enemies")

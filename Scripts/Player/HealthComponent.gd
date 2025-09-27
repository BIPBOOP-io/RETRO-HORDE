extends Node
class_name HealthComponent

# Handles health, regen and health-related feedback, while letting Player keep gameplay state.

var player: Node = null
var hud: Node = null
var regen_timer: Timer
var regen_interval: float = 2.0

func _ready():
	regen_timer = Timer.new()
	regen_timer.one_shot = false
	add_child(regen_timer)

func setup(p: Node, hud_ref: Node, regen_int: float = 2.0) -> void:
	player = p
	hud = hud_ref
	regen_interval = regen_int
	regen_timer.wait_time = regen_interval

func start_regen() -> void:
	if regen_timer and not regen_timer.timeout.is_connected(_on_regen_tick):
		regen_timer.timeout.connect(_on_regen_tick)
	regen_timer.start()

func stop_regen() -> void:
	if regen_timer:
		regen_timer.stop()

func damage(amount: int) -> void:
	if player == null:
		return
	# Shield check
	if player.has_shield:
		player.has_shield = false
		return
	# Apply damage
	player.health -= amount
	_update_health_ui()
	# Feedback + hit animation
	if player.feedback:
		player.feedback.flash_red()
		player.feedback.shake_camera()
	if player.has_method("start_hit") and player.health > 0:
		player.start_hit()
	# Death
	if player.health <= 0 and player.has_method("die"):
		player.die()

func apply_vampirism(damage_dealt: int) -> void:
	if player == null:
		return
	if player.vampirism <= 0.0:
		return
	if player.health >= player.max_health:
		return
	var heal_amount = max(1, round(damage_dealt * player.vampirism))
	var new_health = min(player.max_health, player.health + heal_amount)
	if new_health > player.health:
		player.health = new_health
		_update_health_ui()
		var settings := get_node_or_null("/root/Settings")
		if settings and settings.has_method("is_heal_feedback_on") and settings.is_heal_feedback_on():
			if player.feedback:
				player.feedback.flash_green()

func _on_regen_tick():
	if player == null:
		return
	if player.health < player.max_health:
		player.health += 1
		_update_health_ui()
		var settings := get_node_or_null("/root/Settings")
		if settings and settings.has_method("is_heal_feedback_on") and settings.is_heal_feedback_on():
			if player.feedback:
				player.feedback.flash_green()

func _update_health_ui() -> void:
	if hud and hud.has_method("update_health"):
		hud.update_health(player.health, player.max_health)
	if player.health_bar_2d and player.health_bar_2d.has_method("set_values"):
		player.health_bar_2d.set_values(player.health, player.max_health)

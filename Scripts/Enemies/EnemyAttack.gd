extends Node
class_name EnemyAttack

# Component that encapsulates enemy melee attack logic: trigger, FX, hitbox, and timing.
# Attach this as a child node named "Attack" under an Enemy node.

# References (assigned in setup)
var host: Node = null
var animated_sprite: AnimatedSprite2D = null
var attack_fx: AnimatedSprite2D = null
var attack_area: Area2D = null
var attack_shape: CollisionShape2D = null

# Cached params pulled from host exports during setup
var attack_trigger_distance: float
var attack_windup: float
var attack_active: float
var attack_recovery: float
var attack_hitbox_offset: float
var attack_cancel_factor: float
var cancel_on_escape: bool
var attack_player_knockback: float
var self_knockback_on_attack: float
var attack_hitbox_radius: float
var use_frame_markers: bool
var active_frame_start: int
var active_frame_end: int
var damage_cooldown: float

var _last_attack_time: float = 0.0
var _marker_active: bool = false
var _attack_has_hit: bool = false

func setup(enemy: Node, anim: AnimatedSprite2D, fx: AnimatedSprite2D, area: Area2D, shape: CollisionShape2D, hitbox_template: Area2D = null, config: EnemyAttackConfig = null) -> void:
	host = enemy
	animated_sprite = anim
	attack_fx = fx
	attack_area = area
	attack_shape = shape

	# Copy parameters from host exports, optionally overridden by config Resource
	attack_trigger_distance = float(host.attack_trigger_distance)
	attack_windup = float(host.attack_windup)
	attack_active = float(host.attack_active)
	attack_recovery = float(host.attack_recovery)
	attack_hitbox_offset = float(host.attack_hitbox_offset)
	attack_cancel_factor = float(host.attack_cancel_factor)
	cancel_on_escape = bool(host.attack_cancel_on_escape)
	attack_player_knockback = float(host.attack_player_knockback)
	self_knockback_on_attack = float(host.self_knockback_on_attack)
	attack_hitbox_radius = float(host.attack_hitbox_radius)
	use_frame_markers = bool(host.use_frame_markers)
	active_frame_start = int(host.active_frame_start)
	active_frame_end = int(host.active_frame_end)
	damage_cooldown = float(host.damage_cooldown)

	if config != null:
		attack_trigger_distance = config.attack_trigger_distance
		attack_windup = config.attack_windup
		attack_active = config.attack_active
		attack_recovery = config.attack_recovery
		attack_hitbox_offset = config.attack_hitbox_offset
		attack_cancel_factor = config.attack_cancel_factor
		cancel_on_escape = config.cancel_on_escape
		attack_player_knockback = config.attack_player_knockback
		self_knockback_on_attack = config.self_knockback_on_attack
		attack_hitbox_radius = config.attack_hitbox_radius
		use_frame_markers = config.use_frame_markers
		active_frame_start = config.active_frame_start
		active_frame_end = config.active_frame_end
		damage_cooldown = config.damage_cooldown

	_last_attack_time = -damage_cooldown

	if attack_area:
		if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
			attack_area.body_entered.connect(_on_attack_area_body_entered)
		if hitbox_template:
			var before_layer = attack_area.collision_layer
			var before_mask = attack_area.collision_mask
			attack_area.collision_layer = hitbox_template.collision_layer
			attack_area.collision_mask = hitbox_template.collision_mask
			if before_layer != attack_area.collision_layer or before_mask != attack_area.collision_mask:
				if host and host.has_method("push_warning"):
					host.push_warning("AttackArea filters adjusted to match Hitbox")
	if attack_shape and attack_shape.shape is CircleShape2D and attack_hitbox_radius > 0.0:
		(attack_shape.shape as CircleShape2D).radius = attack_hitbox_radius

	if animated_sprite and not animated_sprite.frame_changed.is_connected(_on_anim_frame_changed):
		animated_sprite.frame_changed.connect(_on_anim_frame_changed)
	if animated_sprite and not animated_sprite.animation_finished.is_connected(_on_anim_finished):
		animated_sprite.animation_finished.connect(_on_anim_finished)
	if attack_fx and not attack_fx.animation_finished.is_connected(_on_attackfx_finished):
		attack_fx.animation_finished.connect(_on_attackfx_finished)

func is_attacking() -> bool:
	return host != null and host.state == host.State.ATTACK

func try_update(player: Node2D, last_dir_str: String) -> void:
	if host == null or player == null:
		return
	if host.state != host.State.WALK:
		return
	var dist: float = (player.global_position - host.global_position).length()
	var now := Time.get_ticks_msec() / 1000.0
	if dist <= attack_trigger_distance and (now - _last_attack_time) >= damage_cooldown:
		_last_attack_time = now
		await _start_attack(player, last_dir_str)

func cancel() -> void:
	_attack_area_enable(false)
	_marker_active = false
	_set_attack_fx(false)

func _start_attack(player: Node2D, last_dir_str: String) -> void:
	if host.state == host.State.DIE:
		return
	host.state = host.State.ATTACK
	# Play body animation using host helper
	if host.has_method("_play_dir_anim"):
		host._play_dir_anim("attack")
	_set_attack_fx(true, last_dir_str)
	_attack_has_hit = false

	if use_frame_markers and animated_sprite:
		await get_tree().create_timer(attack_windup).timeout
		if cancel_on_escape and (player.global_position - host.global_position).length() > attack_trigger_distance * attack_cancel_factor:
			_end_attack()
			return
		# After windup, frames will drive the hitbox and _on_anim_finished will end attack
		return
	else:
		await get_tree().create_timer(attack_windup).timeout
		if cancel_on_escape and (player.global_position - host.global_position).length() > attack_trigger_distance * attack_cancel_factor:
			_end_attack()
			return
		_attack_area_enable(true)
		await get_tree().create_timer(attack_active).timeout
		_attack_area_enable(false)
		await get_tree().create_timer(attack_recovery).timeout
		_end_attack()

func _attack_area_enable(enable: bool) -> void:
	if attack_area == null:
		return
	if enable:
		_position_attack_area()
		attack_area.set_deferred("monitoring", true)
		attack_area.set_deferred("monitorable", true)
		call_deferred("_apply_attack_overlap_damage")
	else:
		attack_area.set_deferred("monitoring", false)
		attack_area.set_deferred("monitorable", false)

func _position_attack_area() -> void:
	if attack_area == null:
		return
	var offs := attack_hitbox_offset
	var s: String = "down"
	if host != null:
		if host.has_method("_dir_to_str"):
			s = String(host.last_dir_str)
	match s:
		"left": attack_area.position = Vector2(-offs, 0)
		"right": attack_area.position = Vector2(offs, 0)
		"up": attack_area.position = Vector2(0, -offs)
		_: attack_area.position = Vector2(0, offs)

func _set_attack_fx(show: bool, last_dir_str: String = "down") -> void:
	if attack_fx == null:
		return
	if show:
		attack_fx.visible = true
		attack_fx.frame = 0
		var fx_anim := "attackfx_%s" % last_dir_str
		if attack_fx.sprite_frames and attack_fx.sprite_frames.has_animation(fx_anim):
			attack_fx.play(fx_anim)
		elif attack_fx.sprite_frames and attack_fx.sprite_frames.has_animation("attackfx"):
			attack_fx.play("attackfx")
	else:
		attack_fx.stop()
		attack_fx.visible = false

func _end_attack() -> void:
	_attack_area_enable(false)
	_marker_active = false
	_set_attack_fx(false)
	if host and host.state != host.State.DIE:
		host.state = host.State.WALK

func _apply_attack_overlap_damage() -> void:
	if attack_area == null or host == null:
		return
	if host.state != host.State.ATTACK or _attack_has_hit:
		return
	if not attack_area.monitoring:
		return
	if not attack_area.has_method("get_overlapping_bodies"):
		return
	for b in attack_area.get_overlapping_bodies():
		if b and b.is_in_group("player"):
			_on_attack_area_body_entered(b)
			break

func _on_attack_area_body_entered(body: Node) -> void:
	if host == null or host.state != host.State.ATTACK or _attack_has_hit:
		return
	if body and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(int(host.damage))
		var dir: Vector2 = Vector2.ZERO
		if body is Node2D:
			dir = ((body as Node2D).global_position - host.global_position).normalized()
		if body.has_method("apply_knockback") and attack_player_knockback > 0.0:
			body.apply_knockback(dir, attack_player_knockback)
		if self_knockback_on_attack > 0.0 and host.has_method("apply_knockback"):
			host.apply_knockback(-dir, self_knockback_on_attack)
		_attack_has_hit = true

func _on_anim_frame_changed() -> void:
	if not use_frame_markers or host == null or host.state != host.State.ATTACK:
		return
	if animated_sprite == null:
		return
	var an := animated_sprite.animation
	if an == null or not an.begins_with("attack"):
		return
	var f := animated_sprite.frame
	if f >= active_frame_start and f <= active_frame_end:
		if not _marker_active:
			_attack_area_enable(true)
			_marker_active = true
	else:
		if _marker_active:
			_attack_area_enable(false)
			_marker_active = false

func _on_anim_finished() -> void:
	if host and host.state == host.State.ATTACK:
		_end_attack()

func _on_attackfx_finished() -> void:
	_set_attack_fx(false)

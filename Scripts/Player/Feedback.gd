extends Node
class_name Feedback

var player: Node = null
var camera: Camera2D = null
var active_tween: Tween = null
var _flash_id: int = 0
var target_node: CanvasItem = null
var base_modulate: Color = Color(1, 1, 1, 1)

func setup(player_ref: Node) -> void:
	player = player_ref
	# Prefer the active camera of the player's viewport
	if player and player.get_viewport():
		camera = player.get_viewport().get_camera_2d()
	if camera == null:
		camera = get_tree().root.find_node("Camera2D", true, false)
	# Tweens in Godot 4 are created per use via create_tween()
	# Choose a visual target to tint that is NOT the whole player to avoid affecting bars
	if player and player.has_node("AnimatedSprite2D"):
		var spr := player.get_node("AnimatedSprite2D")
		if spr is CanvasItem:
			target_node = spr
	elif player and player.has_node("Sprite2D"):
		var spr2 := player.get_node("Sprite2D")
		if spr2 is CanvasItem:
			target_node = spr2
	# Fallback disabled: do not tint the whole player node to avoid coloring bars
	if target_node:
		base_modulate = target_node.modulate

func flash_red() -> void:
	await _flash_color(Color(1, 0, 0))

func flash_green() -> void:
	await _flash_color(Color(0, 1, 0))

func flash_gold() -> void:
	await _flash_color(Color(1, 0.84, 0))

func _flash_color(color: Color) -> void:
	if player == null:
		return
	var target: CanvasItem = target_node
	if target == null:
		return
	_flash_id += 1
	var this_id := _flash_id
	target.modulate = color
	await get_tree().create_timer(0.2).timeout
	if _flash_id == this_id:
		target.modulate = base_modulate

func shake_camera(amount: float = 10.0, duration: float = 0.2) -> void:
	# Use SceneTreeTween API in Godot 4
	if camera == null:
		if player and player.get_viewport():
			camera = player.get_viewport().get_camera_2d()
		if camera == null:
			return
	if active_tween:
		active_tween.kill()
		active_tween = null
	var original := camera.position
	var half := duration * 0.5
	active_tween = get_tree().create_tween()
	active_tween.tween_property(
		camera, "position",
		original + Vector2(randf_range(-amount, amount), randf_range(-amount, amount)),
		half
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tween.tween_property(
		camera, "position",
		original,
		half
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func spawn_particles(packed_scene: PackedScene) -> void:
	if player == null or packed_scene == null:
		return
	var particles = packed_scene.instantiate()
	if particles is Node2D:
		(particles as Node2D).global_position = player.global_position
	if player.get_parent():
		player.get_parent().add_child(particles)
	else:
		add_child(particles)

# Persistent tint (e.g., shield active)
func set_tint(color: Color) -> void:
	if target_node == null:
		return
	base_modulate = color
	target_node.modulate = color

func clear_tint() -> void:
	if target_node == null:
		return
	base_modulate = Color(1, 1, 1, 1)
	target_node.modulate = base_modulate

extends Area2D

@export var speed: float = 200.0
@export var max_distance: float = 100.0
@export var damage: int = 1
@export var base_knockback: float = 100.0

var knockback_multiplier: float = 1.0
var traveled_distance: float = 0.0
var direction: Vector2 = Vector2.ZERO

# ✅ nouveaux
var pierce_left: int = 0
var crit_chance: float = 0.0
var crit_multiplier: float = 2.0

# ✅ texte flottant (assigne FloatingText.tscn dans l’inspecteur)
@export var floating_text_scene: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready():
	if direction != Vector2.ZERO:
		rotation = direction.angle()

func _physics_process(delta):
	if direction == Vector2.ZERO: return

	var move = direction.normalized() * speed * delta
	position += move
	traveled_distance += move.length()

	if traveled_distance >= max_distance:
		queue_free()

func _on_body_entered(body: Node):
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			# ✅ Critique
			var final_damage = damage
			if randf() < crit_chance:
				final_damage = int(damage * crit_multiplier)
				_show_floating_text(body.global_position, "CRIT!")

			body.take_damage(final_damage)

			# ✅ Knockback
			if body.has_method("apply_knockback"):
				var force = base_knockback * knockback_multiplier
				body.apply_knockback(direction, force)

			# ✅ Vampirisme
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("heal_from_vampirism"):
				player.heal_from_vampirism(final_damage)

		# ✅ Gestion de la perforation
		pierce_left -= 1
		if pierce_left < 0:
			queue_free()

# ==========================
#   Feedback texte flottant
# ==========================
func _show_floating_text(pos: Vector2, text: String):
	if floating_text_scene:
		var t = floating_text_scene.instantiate()
		t.text = text
		t.global_position = pos + Vector2(0, -10)  # léger décalage au-dessus
		get_parent().add_child(t)

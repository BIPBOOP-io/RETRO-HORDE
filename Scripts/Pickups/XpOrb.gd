extends Area2D

@export var xp_value: int = 1  # Par défaut

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		if body.has_method("gain_xp"):
			body.gain_xp(xp_value)
		queue_free()

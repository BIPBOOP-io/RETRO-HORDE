extends Area2D

@export var xp_value: int = 1

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		if body.has_method("gain_xp"):
			body.gain_xp(xp_value)
		queue_free()

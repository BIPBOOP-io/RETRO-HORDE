extends Label

@export var float_speed: float = 30.0
@export var lifetime: float = 0.8

func _ready():
# float up then fade out
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 30, lifetime)
	tween.parallel().tween_property(self, "modulate:a", 0.0, lifetime)
	tween.tween_callback(Callable(self, "queue_free"))

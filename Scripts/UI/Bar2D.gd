extends Node2D

@export var size: Vector2 = Vector2(48, 6)
@export var bg_color: Color = Color(0, 0, 0, 0.5)
@export var fill_color: Color = Color(1, 0, 0, 1)
@export var outline_color: Color = Color(0, 0, 0, 0.9)
@export var outline_width: float = 1.0
@export var hide_when_full: bool = false

var max_value: float = 100.0
var value: float = 100.0

func _draw():
	var w: float = float(size.x)
	var h: float = float(size.y)

	# Outline
	if outline_width > 0.0:
		draw_rect(Rect2(Vector2(-w/2.0 - outline_width, -h/2.0 - outline_width), Vector2(w + outline_width*2.0, h + outline_width*2.0)), outline_color, false, 1.0)

	# Background
	draw_rect(Rect2(Vector2(-w/2.0, -h/2.0), size), bg_color)

	# Fill
	var ratio: float = 0.0
	if max_value > 0.0:
		ratio = clamp(value / max_value, 0.0, 1.0)
	var fill_w: float = w * ratio
	if fill_w > 0.0:
		draw_rect(Rect2(Vector2(-w/2.0, -h/2.0), Vector2(fill_w, h)), fill_color)

func set_values(current: float, max_v: float) -> void:
	max_value = max(0.0001, max_v)
	value = clamp(current, 0.0, max_value)
	if hide_when_full:
		visible = value < max_value
	queue_redraw()

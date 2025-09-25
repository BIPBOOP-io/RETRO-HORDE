extends CanvasLayer

@onready var slide_panel := ColorRect.new()

const SLIDE_COLOR: Color = Color.BLACK
const SLIDE_TIME: float = 0.25

# Possible directions
enum Direction { LEFT, RIGHT, UP, DOWN }

func _ready() -> void:
	slide_panel.color = SLIDE_COLOR
	slide_panel.visible = false
	slide_panel.size = get_viewport().get_visible_rect().size
	add_child(slide_panel)
	layer = 100

func change_scene_to_packed(scene: PackedScene, direction: int = Direction.RIGHT) -> void:
	_slide_out(direction,
		func():
			get_tree().change_scene_to_packed(scene)
			_slide_in(direction)
	)

func change_scene_to_file(path: String, direction: int = Direction.RIGHT) -> void:
	_slide_out(direction,
		func():
			get_tree().change_scene_to_file(path)
			_slide_in(direction)
	)

# --------------------------
# Slide helpers
# --------------------------
func _slide_out(direction: int, callback: Callable) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	slide_panel.visible = true
	slide_panel.size = viewport_size

	match direction:
		Direction.LEFT:
			slide_panel.position = Vector2(viewport_size.x, 0)   # start offscreen right
			_animate(Vector2(0, 0), callback)
		Direction.RIGHT:
			slide_panel.position = Vector2(-viewport_size.x, 0)  # start offscreen left
			_animate(Vector2(0, 0), callback)
		Direction.UP:
			slide_panel.position = Vector2(0, viewport_size.y)   # start offscreen bottom
			_animate(Vector2(0, 0), callback)
		Direction.DOWN:
			slide_panel.position = Vector2(0, -viewport_size.y)  # start offscreen top
			_animate(Vector2(0, 0), callback)

func _slide_in(direction: int) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	slide_panel.position = Vector2(0, 0)
	var target: Vector2

	match direction:
		Direction.LEFT:
			target = Vector2(-viewport_size.x, 0)
		Direction.RIGHT:
			target = Vector2(viewport_size.x, 0)
		Direction.UP:
			target = Vector2(0, -viewport_size.y)
		Direction.DOWN:
			target = Vector2(0, viewport_size.y)

	_animate(target, func(): slide_panel.visible = false)

func _animate(target: Vector2, callback: Callable) -> void:
	var tween := create_tween()
	tween.tween_property(slide_panel, "position", target, SLIDE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(callback)

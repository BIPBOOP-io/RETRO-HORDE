extends CharacterBody2D

@export var speed: float = 40.0
@export var move_interval: float = 2.0    # every X seconds, pick a new direction
@export var idle_chance: float = 0.3      # probability to idle instead of moving

var move_dir: Vector2 = Vector2.ZERO
var timer: Timer
var animated_sprite: AnimatedSprite2D

func _ready():
	animated_sprite = $AnimatedSprite2D
	timer = Timer.new()
	timer.wait_time = move_interval
	timer.autostart = true
	timer.one_shot = false
	add_child(timer)
	timer.timeout.connect(_choose_new_direction)

	_choose_new_direction()

func _physics_process(_delta):
	if move_dir != Vector2.ZERO:
		velocity = move_dir * speed
		move_and_slide()
		_play_walk_animation(move_dir)
	else:
		animated_sprite.play("idle_down")

func _choose_new_direction():
	if randf() < idle_chance:
		move_dir = Vector2.ZERO
	else:
		move_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func _play_walk_animation(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			animated_sprite.play("walk_right")
		else:
			animated_sprite.play("walk_left")
	else:
		if dir.y > 0:
			animated_sprite.play("walk_down")
		else:
			animated_sprite.play("walk_up")

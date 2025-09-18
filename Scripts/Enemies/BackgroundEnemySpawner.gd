extends Node2D

@export var background_enemy_scene: PackedScene    # assigne BackgroundEnemy.tscn dans l’inspecteur
@export var enemy_count: int = 5                   # nombre d'ennemis de fond à spawn
@export var spawn_area: Rect2 = Rect2(Vector2(-400, -200), Vector2(800, 400))
# Rect2(position, size) → zone dans laquelle les ennemis spawnent

func _ready():
	for i in range(enemy_count):
		_spawn_enemy()

func _spawn_enemy():
	if not background_enemy_scene:
		return

	var enemy = background_enemy_scene.instantiate()
	var random_pos = Vector2(
		randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
		randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	)
	enemy.global_position = random_pos
	add_child(enemy)

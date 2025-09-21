extends Node
class_name AttackController

# Minimal skeleton to host attack logic.

var player: Node = null
var get_enemies: Callable
var attack_timer: Timer

func _ready():
    # Timer is created but not started; Player keeps current logic until migrated.
    attack_timer = Timer.new()
    attack_timer.one_shot = false
    add_child(attack_timer)

func setup(p: Node, get_enemies_fn: Callable, attack_interval: float) -> void:
    player = p
    get_enemies = get_enemies_fn
    set_attack_interval(max(0.01, attack_interval))

func set_attack_interval(seconds: float) -> void:
    if attack_timer:
        attack_timer.wait_time = seconds

func start_auto_attack() -> void:
    if attack_timer and not attack_timer.timeout.is_connected(_on_attack_tick):
        attack_timer.timeout.connect(_on_attack_tick)
    if attack_timer:
        attack_timer.start()

func stop_auto_attack() -> void:
    if attack_timer:
        attack_timer.stop()

func _on_attack_tick() -> void:
    if player == null:
        return
    var enemies: Array = []
    if get_enemies.is_valid():
        enemies = get_enemies.call()
    if enemies.is_empty():
        return

    var closest_enemy = null
    var closest_dist_sq: float = INF
    for e in enemies:
        var dist_sq = player.global_position.distance_squared_to(e.global_position)
        if dist_sq < closest_dist_sq:
            closest_dist_sq = dist_sq
            closest_enemy = e

    if closest_enemy and closest_dist_sq <= player.attack_range * player.attack_range:
        var dir: Vector2 = (closest_enemy.global_position - player.global_position).normalized()
        for i in range(player.multi_shot):
            var delay = i * 0.3
            if player.has_method("_fire_arrow_salvo"):
                player._fire_arrow_salvo(dir, delay)

func fire_special(dir: Vector2, params: Dictionary = {}):
    # Placeholder for a future migration of the giant arrow logic.
    pass

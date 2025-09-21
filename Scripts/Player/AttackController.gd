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
    # Placeholder: keep current Player.gd implementation for now.
    # You can migrate Player._auto_attack() here and call it instead.
    pass

func fire_special(dir: Vector2, params: Dictionary = {}):
    # Placeholder for a future migration of the giant arrow logic.
    pass


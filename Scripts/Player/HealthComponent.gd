extends Node
class_name HealthComponent

# Minimal skeleton to host health/damage/regen logic.

var player: Node = null
var hud: Node = null
var regen_timer: Timer

func _ready():
    regen_timer = Timer.new()
    regen_timer.one_shot = false
    add_child(regen_timer)

func setup(p: Node, hud_ref: Node, regen_interval: float = 2.0) -> void:
    player = p
    hud = hud_ref
    regen_timer.wait_time = regen_interval

func start_regen() -> void:
    if regen_timer and not regen_timer.timeout.is_connected(_on_regen_tick):
        regen_timer.timeout.connect(_on_regen_tick)
    regen_timer.start()

func stop_regen() -> void:
    if regen_timer:
        regen_timer.stop()

func damage(amount: int) -> void:
    # Placeholder – keep Player.take_damage for now.
    pass

func apply_vampirism(damage_dealt: int) -> void:
    # Placeholder – keep Player.heal_from_vampirism for now.
    pass

func _on_regen_tick():
    # Placeholder – keep Player._on_regen_tick for now.
    pass


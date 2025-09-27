extends Node
class_name StaminaComponent

var player: Node = null
var hud: Node = null
var bar_2d: Node2D = null

var max_value: float = 100.0
var value: float = 100.0
var drain_per_sec: float = 20.0
var regen_per_sec: float = 12.0
var ready_fraction: float = 0.25
var locked: bool = false

func setup(p: Node, hud_ref: Node = null, stamina_bar_2d: Node2D = null, cfg: Dictionary = {}) -> void:
    player = p
    hud = hud_ref
    bar_2d = stamina_bar_2d

    # Pull defaults from player exports if present
    if cfg.has("max_value"): max_value = float(cfg.max_value)
    elif player and "max_stamina" in player: max_value = float(player.max_stamina)

    if cfg.has("value"): value = float(cfg.value)
    elif player and "stamina" in player: value = float(player.stamina)

    if cfg.has("drain"): drain_per_sec = float(cfg.drain)
    elif player and "stamina_drain_per_sec" in player: drain_per_sec = float(player.stamina_drain_per_sec)

    if cfg.has("regen"): regen_per_sec = float(cfg.regen)
    elif player and "stamina_regen_per_sec" in player: regen_per_sec = float(player.stamina_regen_per_sec)

    if cfg.has("ready_fraction"): ready_fraction = float(cfg.ready_fraction)
    elif player and "stamina_ready_fraction" in player: ready_fraction = float(player.stamina_ready_fraction)

    # Initialize lock based on current value
    locked = false
    if value <= 0.0:
        locked = true

    _sync_player_field()
    _update_ui(true)

func can_sprint() -> bool:
    if value <= 0.0:
        return false
    var thr := max_value * ready_fraction
    if locked and value < thr:
        return false
    return true

func tick(delta: float, is_sprinting: bool) -> void:
    if is_sprinting:
        var prev := value
        value = max(0.0, value - drain_per_sec * delta)
        if value <= 0.0 and prev > 0.0:
            locked = true
    else:
        value = min(max_value, value + regen_per_sec * delta)

    var thr := max_value * ready_fraction
    if locked and value >= thr:
        locked = false

    _sync_player_field()
    _update_ui(is_sprinting)

func _sync_player_field() -> void:
    if player and "stamina" in player:
        player.stamina = value

func _update_ui(is_sprinting: bool) -> void:
    if hud and hud.has_method("update_stamina"):
        hud.update_stamina(value, max_value)

    if bar_2d and bar_2d.has_method("set_values"):
        # Orange only while recovering below threshold after full depletion
        var thr := max_value * ready_fraction
        if (not is_sprinting) and locked and value < thr:
            bar_2d.fill_color = Color(1, 0.5, 0, 1)
        else:
            bar_2d.fill_color = Color(1, 0.85, 0, 1)
        bar_2d.set_values(value, max_value)


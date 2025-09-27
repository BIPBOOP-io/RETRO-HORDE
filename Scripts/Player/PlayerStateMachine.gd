extends Node
class_name PlayerStateMachine

enum State { IDLE, MOVE, HIT, DIE, FALLING, CAST }

var state: int = State.IDLE
var last_dir_str: String = "down"
var animated_sprite: AnimatedSprite2D = null

func setup(anim: AnimatedSprite2D) -> void:
    animated_sprite = anim
    state = State.IDLE
    last_dir_str = "down"

func allow_input() -> bool:
    return state == State.IDLE or state == State.MOVE

func in_state(s: int) -> bool:
    return state == s

func update_direction(dir: Vector2) -> void:
    if abs(dir.x) > abs(dir.y):
        last_dir_str = "right" if dir.x > 0 else "left"
    else:
        last_dir_str = "down" if dir.y > 0 else "up"

func _play_dir_anim(prefix: String) -> void:
    if animated_sprite == null or animated_sprite.sprite_frames == null:
        return
    var an := "%s_%s" % [prefix, last_dir_str]
    if animated_sprite.sprite_frames.has_animation(an):
        animated_sprite.play(an)
    elif animated_sprite.sprite_frames.has_animation(prefix):
        animated_sprite.play(prefix)

func play_walk(dir: Vector2) -> void:
    if state == State.HIT or state == State.CAST or state == State.DIE or state == State.FALLING:
        return
    state = State.MOVE
    # Use direct names for walk_* if available
    if animated_sprite and animated_sprite.sprite_frames:
        if abs(dir.x) > abs(dir.y):
            if dir.x > 0 and animated_sprite.sprite_frames.has_animation("walk_right"):
                animated_sprite.play("walk_right")
            elif animated_sprite.sprite_frames.has_animation("walk_left"):
                animated_sprite.play("walk_left")
        else:
            if dir.y > 0 and animated_sprite.sprite_frames.has_animation("walk_down"):
                animated_sprite.play("walk_down")
            elif animated_sprite.sprite_frames.has_animation("walk_up"):
                animated_sprite.play("walk_up")

func play_idle() -> void:
    if state == State.HIT or state == State.CAST or state == State.DIE or state == State.FALLING:
        return
    state = State.IDLE
    _play_dir_anim("idle")

func play_hit(duration: float) -> void:
    if state == State.DIE or state == State.FALLING:
        return
    state = State.HIT
    _play_dir_anim("hit")
    await get_tree().create_timer(max(0.05, duration)).timeout
    if state == State.HIT:
        state = State.IDLE
        _play_dir_anim("idle")

func play_cast(duration: float, after_cb: Callable) -> void:
    if state == State.DIE or state == State.FALLING:
        return
    state = State.CAST
    _play_dir_anim("cast")
    await get_tree().create_timer(max(0.05, duration)).timeout
    if state != State.DIE and state != State.FALLING:
        if after_cb.is_valid():
            after_cb.call()
        state = State.IDLE
        _play_dir_anim("idle")

func play_die(duration: float, after_cb: Callable) -> void:
    if state == State.DIE:
        return
    state = State.DIE
    _play_dir_anim("die")
    await get_tree().create_timer(max(0.05, duration)).timeout
    if after_cb.is_valid():
        after_cb.call()


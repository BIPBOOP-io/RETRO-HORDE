extends Resource
class_name EnemyAttackConfig

@export var attack_trigger_distance: float = 40.0
@export var attack_windup: float = 0.12
@export var attack_active: float = 0.10
@export var attack_recovery: float = 0.2
@export var attack_hitbox_offset: float = 16.0
@export var attack_cancel_factor: float = 1.1
@export var cancel_on_escape: bool = false
@export var attack_player_knockback: float = 180.0
@export var self_knockback_on_attack: float = 40.0
@export var attack_hitbox_radius: float = 12.0
@export var use_frame_markers: bool = false
@export var active_frame_start: int = 1
@export var active_frame_end: int = 3
@export var damage_cooldown: float = 1.0

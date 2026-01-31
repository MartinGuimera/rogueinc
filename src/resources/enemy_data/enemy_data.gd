@tool
class_name EnemyData
extends Resource

@export var enemy_name: String = "Enemy Name"
@export var health: float = 50.0
@export var sprite: Texture2D

# Future properties for AI and attacks
@export_group("Behavior")
@export var damage: float = 5.0
@export var attack_cooldown: float = 2.0

class_name Enemy
extends Entity

@export var enemy_data: EnemyData

func _ready() -> void:
	if enemy_data:
		self.max_health = enemy_data.health
	super()
	died.connect(_on_death)

func _on_death() -> void:
	print("Enemy '%s' has been defeated." % enemy_data.enemy_name if enemy_data else "Enemy")
	queue_free()

# In the future, an AI controller would use enemy_data
# to decide when to add to the BattleManager's enemy_pending_damage pool.

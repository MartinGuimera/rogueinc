class_name Entity
extends Node2D

signal health_changed(current_health, max_health)
signal shield_changed(current_shield)
signal died

@export var max_health: float = 100.0
var current_health: float:
	set(value):
		current_health = clampf(value, 0, max_health)
		health_changed.emit(current_health, max_health)
		if current_health == 0:
			died.emit()

var current_shield: float = 0.0:
	set(value):
		current_shield = maxf(0, value)
		shield_changed.emit(current_shield)

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float) -> void:
	if amount <= 0:
		return

	var damage_to_shield = minf(current_shield, amount)
	self.current_shield -= damage_to_shield
	
	var remaining_damage = amount - damage_to_shield
	self.current_health -= remaining_damage

func add_shield(amount: float) -> void:
	if amount <= 0:
		return
	self.current_shield += amount

func heal(amount: float) -> void:
	if amount <= 0:
		return
	self.current_health += amount

class_name CardUI
extends Node2D

signal card_activated(card_data) # Emitted when the card's internal cooldown finishes
signal hovered(card)
signal hovered_off(card)


@export var card_data: CardData

var is_in_hand: bool = false # Declaración necesaria para evitar el error
var is_in_slot: bool = false
var hand_position: Vector2 = Vector2.ZERO
var current_slot: CardSlot = null
var slot_history: Array[CardSlot] = []


@onready var timer: Timer = Timer.new()

func _ready() -> void:
	if !card_data:
		push_error("CardUI: CardData es nulo en %s" % name)
		return

	_setup_timer()

func _setup_timer() -> void:
	timer.wait_time = card_data.cooldown
	timer.one_shot = false
	timer.timeout.connect(func(): card_activated.emit(card_data))
	add_child(timer)
	timer.start()
	
func _on_cooldown_timeout() -> void:
	# Cooldown finished, let the BattleManager know.
	card_activated.emit(card_data)
	# print("Card '%s' activated!" % card_data.card_name)

func set_slot(new_slot: CardSlot) -> void:
	current_slot = new_slot
	if new_slot:
		is_in_slot = true
		# Si quieres guardar el historial:
		if not slot_history.has(new_slot):
			slot_history.append(new_slot)
	else:
		is_in_slot = false

func _on_area_2d_mouse_entered () -> void:
	emit_signal("hovered",self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off",self)

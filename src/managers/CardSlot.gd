class_name CardSlot extends Node2D

# Esta variable es la que consultará el CardManager
var card_in_slot: bool = false
var current_card: CardUI = null 
var cards_history: Array[CardUI] = []

func is_occupied() -> bool:
	return current_card != null

func occupy_slot(card: CardUI) -> void:
	current_card = card
	if card.has_method("set_slot"):
		card.set_slot(self)
	
	if not cards_history.has(card):
		cards_history.append(card)

func clear_slot() -> void:
	if current_card and current_card.has_method("set_slot"):
		current_card.set_slot(null)
	current_card = null
	
func get_card() -> CardUI:
	return current_card

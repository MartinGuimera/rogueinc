extends Node2D

const HAND_COUNT = 2

const CARD_HEIGHT = 130
const HAND_X_POSITON = 90
const DEFAULT_CARD_MOVE_SPEED = 0.1

var player_hand = []
var center_screen_y
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_y = get_viewport().size.y/2

func add_card_to_hand(card, speed):
	if card not in player_hand:
		player_hand.insert(0, card)
		if "is_in_hand" in card:
			card.is_in_hand = true 
		update_hand_positions(speed)
	else:
		animate_card_to_position(card, card.hand_position, DEFAULT_CARD_MOVE_SPEED)

func discard_card(card,speed):
	if card not in player_hand and card.card_in_slot:
		player_hand.insert(0,card)
		update_hand_positions(speed)
	else:
		animate_card_to_position(card,card.hand_position,DEFAULT_CARD_MOVE_SPEED)
	
func update_hand_positions(speed):
	for i in range(player_hand.size()):
		var new_position = Vector2(HAND_X_POSITON,calculate_card_position (i))
		var card = player_hand[i]
		card.hand_position = new_position
		animate_card_to_position (card, new_position,speed)
		
func calculate_card_position(index):
	var total_height = (player_hand.size() -1) * CARD_HEIGHT
	
	var y_offset = center_screen_y - index * CARD_HEIGHT + total_height / 2 

	return y_offset

func animate_card_to_position (card, new_position,speed):
	var tween = get_tree().create_tween()
	tween.tween_property(card,"position",new_position,speed)
	
func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		if "is_in_hand" in card: 
			card.is_in_hand = false # Ya no está en la mano
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

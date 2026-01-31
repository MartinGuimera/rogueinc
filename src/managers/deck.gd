extends Node2D


var player_deck = ["Quick Attack","Quick Dodge","Special","Quick Attack","Quick Attack"]
const CARD_SCENE_PATH = "res://scenes/card.tscn"
const CARD_DRAW_SPEED = 0.2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_deck.shuffle()
	$RichTextLabel.text = str(player_deck.size())
	pass


func draw_card():
	var card_drawn = player_deck[0]
	player_deck.erase(card_drawn)
	if player_deck.size() == -1:

			var discard_pile = get_tree().get_first_node_in_group("discard_pile")
			if discard_pile:
				player_deck = discard_pile.collect_discarded_cards()
				player_deck.shuffle()
				print("Mazo rebarajado con: ", player_deck.size(), " cartas.")
		
		
	$RichTextLabel.text = str(player_deck.size())
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)

	
#func _input(event):
#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
	#if event.pressed:
		#var card = raycast_check_for_card()
		#if card :
			#start_drag(card)
	#else:
		#if card_being_dragged:
			#finish_drag()

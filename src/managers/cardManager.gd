extends Node2D


const COLLISION_MASK_CARD: int = 1
const COLLISION_MASK_SLOT: int = 2
const COLLISION_MASK_DISCARD: int = 4
const DEFAULT_CARD_MOVE_SPEED: float = 0.1
const SCALE_HOV: Vector2 = Vector2(4, 4)
const SCALE_HOV_OFF: Vector2 = Vector2(3.5, 3.5)

# Variables con tipado estático para mejor performance y autocompletado
var screen_size: Vector2
var card_being_dragged: CardUI = null
var is_hovering_on_card: bool = false
var was_in_slot: bool = false

@export var player_hand_reference: Node2D 
@export var input_manager: Node 

# Guardamos el slot actual de la carta de forma segura
var current_slot: Node2D = null

func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_realeased", _on_left_button_released)

func _process(_delta: float) -> void:
	if card_being_dragged:
		var mouse_pos := get_global_mouse_position()
		# Clamp para que la carta no salga de la pantalla
		card_being_dragged.global_position = mouse_pos.clamp(Vector2.ZERO, screen_size)

func _on_left_button_released() -> void:
	if card_being_dragged:
		finish_drag()

func start_drag(card: CardUI) -> void:
	card_being_dragged = card
	#card_being_dragged.z_index = 10

func raycast_check_for_card ():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_card_with_max_z_index (result)
	else:
		return null

func raycast_check_for_slot() -> CardSlot:
	var space_state := get_world_2d().direct_space_state
	var parameters := PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_SLOT # Valor: 2 
	
	var results := space_state.intersect_point(parameters)

	print("--- Raycast Slot Check ---")
	print ("results", results)
	
	if results.size() > 0:
		for i in range(results.size()):
			var collider = results[i].collider
			var parent = collider.get_parent()
		
			# Verificamos si el script CardSlot está en el Area2D o en su Padre 
			if collider is CardSlot:
				return collider as CardSlot
				
			elif parent is CardSlot:
				return parent as CardSlot
				
	return null

func raycast_check_for_discard() -> DiscardPile:
	var space_state := get_world_2d().direct_space_state
	var parameters := PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_DISCARD
	
	var results := space_state.intersect_point(parameters)
	for result in results:
		var collider = result.collider
		if collider is DiscardPile: return collider
		if collider.get_parent() is DiscardPile: return collider.get_parent() as DiscardPile
	return null

func get_card_with_max_z_index (cards):
	var max_z_card = cards[0].collider.get_parent()
	var max_z_index = max_z_card.z_index
	
	for i in range (1,cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > max_z_index:
			max_z_card = current_card
			max_z_index = current_card.z_index
	return max_z_card

func finish_drag() -> void:
	if not card_being_dragged: 
		return
	
	card_being_dragged.scale = SCALE_HOV_OFF
	var slot_found: CardSlot = raycast_check_for_slot()

	if card_being_dragged.is_in_slot:
		if slot_found:
			print (slot_found)
			_handle_slot_to_slot_swap(slot_found)
		else:
			# TargetSlot -- No --> ToDiscard
			var pile = get_tree().get_first_node_in_group("discard_pile")
			_discard_from_slot_action(current_slot, pile) 

	else:
		if slot_found:
			_place_card_from_hand_to_slot(slot_found)
		else:
			# TargetNoSlot -- No --> Volver a la mano
			return_card_to_origin()
			
	card_being_dragged = null
	current_slot = null

func _handle_slot_to_slot_swap(new_slot: CardSlot) -> void:
	var old_slot = card_being_dragged.current_slot # El slot de donde venía la carta
	
	if new_slot.is_occupied():
		var card_in_target = new_slot.get_card()
		
		# Limpiamos ambos slots antes de reasignar
		print (new_slot)
		print (old_slot)
		new_slot.clear_slot()
		old_slot.clear_slot()
		
		# Intercambio cruzado
		old_slot.occupy_slot(card_in_target)
		new_slot.occupy_slot(card_being_dragged)
		
		# Animación (puedes usar el tween que ya tienes)
		card_in_target.global_position = old_slot.global_position
	else:
		old_slot.clear_slot()
		new_slot.occupy_slot(card_being_dragged)
	
	card_being_dragged.global_position = new_slot.global_position

func _discard_from_slot_action(origin_slot: CardSlot, pile: DiscardPile) -> void:
	if origin_slot:
		origin_slot.clear_slot() # El slot ahora está vacío y disponible
	
	if pile:
		pile.discard_card(card_being_dragged)
	else:
		# Si no hay pila por error, al menos no la dejes flotando
		card_being_dragged.queue_free()

func _discard_card_action(pile: DiscardPile) -> void:
	if current_slot:
		current_slot.clear_slot()
		current_slot = null
	
	if "is_in_hand" in card_being_dragged and card_being_dragged.is_in_hand:
		player_hand_reference.remove_card_from_hand(card_being_dragged)
	
	pile.discard_card(card_being_dragged)

func _place_card_in_slot(slot: CardSlot) -> void:
	if slot.is_occupied():
		var old_card = slot.get_card()
		var pile = get_tree().get_first_node_in_group("discard_pile")
		if pile:
			_discard_specific_card(old_card, pile)
		slot.clear_slot()
		
	# Si la carta viene de la mano, la removemos del array de PlayerHand
	if card_being_dragged is CardUI:
		card_being_dragged.is_in_slot = true
		card_being_dragged.is_in_hand = false # [cite: 7]
		
	player_hand_reference.remove_card_from_hand(card_being_dragged) # [cite: 5]
	card_being_dragged.global_position = slot.global_position
	slot.occupy_slot(card_being_dragged)
	current_slot = slot

func _place_card_from_hand_to_slot(slot: CardSlot) -> void:
	if slot.is_occupied():
		print ("slot ", slot, "- occupied")
		var old_card = slot.get_card()
		var pile = get_tree().get_first_node_in_group("discard_pile")
		if pile:
			pile.discard_card(old_card)
		slot.clear_slot()
	
	# SlotOccupied -- No (o tras limpiar) --> Anchor
	player_hand_reference.remove_card_from_hand(card_being_dragged)
	card_being_dragged.is_in_hand = false # Importante para la lógica de PlayerHand
	
	slot.occupy_slot(card_being_dragged)
	card_being_dragged.global_position = slot.global_position

func _discard_specific_card(card: CardUI, pile: DiscardPile) -> void:

	if card.has_method("get_current_slot"): 
		var slot = card.get_current_slot()
		if slot: slot.clear_slot()

	if card in player_hand_reference.player_hand:
		player_hand_reference.remove_card_from_hand(card)

	pile.discard_card(card)

func return_card_to_origin() -> void:
	if current_slot:
		# Si ya pertenecía a un slot, vuelve a él
		card_being_dragged.global_position = current_slot.global_position
	else:
		# Si venía de la mano, regresa a ella
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)

func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_hovered_over_card(card):
	if !is_hovering_on_card:
		highlight_card(card, true)
		is_hovering_on_card = true
	
func on_hovered_off_card(card):
	if !card_being_dragged:
		highlight_card(card, false)
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered:
			highlight_card(card, true)
		else:
			is_hovering_on_card = false
	
func highlight_card (card, hovered):
	if hovered:
		card.scale = SCALE_HOV
		card.z_index = 2
	else:
		card.scale = SCALE_HOV_OFF
		card.z_index = 1

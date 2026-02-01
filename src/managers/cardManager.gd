extends Node2D

const COLLISION_MASK_CARD: int = 1
const COLLISION_MASK_SLOT: int = 2
const COLLISION_MASK_DISCARD: int = 4
const DEFAULT_CARD_MOVE_SPEED: float = 0.1
const SCALE_HOV: Vector2 = Vector2(4, 4)
const SCALE_HOV_OFF: Vector2 = Vector2(3.5, 3.5)

var screen_size: Vector2
var card_being_dragged: CardUI = null
var is_hovering_on_card: bool = false

@export var player_hand_reference: Node2D 
@export var input_manager: Node 

func _ready() -> void:
	screen_size = get_viewport_rect().size
	# Es recomendable asignar estas rutas por Export en el inspector para evitar errores de ruta
	if !player_hand_reference: player_hand_reference = $"../PlayerHand"
	
	var im = $"../InputManager"
	if im:
		im.connect("left_mouse_button_realeased", _on_left_button_released)

func _process(_delta: float) -> void:
	if card_being_dragged:
		var mouse_pos := get_global_mouse_position()
		card_being_dragged.global_position = mouse_pos.clamp(Vector2.ZERO, screen_size)

func _on_left_button_released() -> void:
	if card_being_dragged:
		finish_drag()

func start_drag(card: CardUI) -> void:
	card_being_dragged = card
	card_being_dragged.z_index = 10 # Asegurar que esté por encima de todo al arrastrar

# --- SISTEMA UNIFICADO DE RAYCAST ---
func _check_collision_at_mouse(mask: int):
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = mask
	return space_state.intersect_point(parameters)

func raycast_check_for_slot() -> CardSlot:
	var results = _check_collision_at_mouse(COLLISION_MASK_SLOT)
	if results.is_empty(): return null
	
	var collider = results[0].collider
	if collider is CardSlot: return collider
	if collider.get_parent() is CardSlot: return collider.get_parent()
	return null

# --- LÓGICA DE FINALIZACIÓN ---
func finish_drag() -> void:
	if not card_being_dragged: 
		return

	card_being_dragged.scale = SCALE_HOV_OFF
	var slot_found: CardSlot = raycast_check_for_slot()
	
	# --- RAMA: La carta ya estaba en un slot ---
	if card_being_dragged.is_in_slot: 
		if slot_found:
			# Si cae en un slot (nuevo o el mismo), gestionamos el cambio
			_swap_cards(card_being_dragged,slot_found)
		else:
			# Si cae en el vacío (no hay slot), se descarta directamente 
			var pile = get_tree().get_first_node_in_group("discard_pile")
			_perform_discard(card_being_dragged, pile)
	
	# --- RAMA: La carta viene de la mano ---
	else:
		if slot_found:
			# Se intenta colocar en el slot
			_handle_card_placement(card_being_dragged,slot_found)
		else:
			# Vuelve a la mano si no hay slot
			return_card_to_origin()
			
	card_being_dragged = null

# --- FUNCIONES DE SOPORTE UNIFICADAS ---

func _handle_card_placement(card: CardUI, new_slot: CardSlot) -> void:
	# Si venía de otro slot, lo liberamos
	if card.is_in_slot and card.current_slot:
		if new_slot.is_occupied():
			_swap_cards(card, new_slot)
		else:
			card.current_slot.clear_slot()
			_anchor_card_to_slot(card, new_slot)
	else:
		# Viene de la mano
		if new_slot.is_occupied():
			_perform_discard(new_slot.get_card(), get_tree().get_first_node_in_group("discard_pile"))
		
		player_hand_reference.remove_card_from_hand(card)
		_anchor_card_to_slot(card, new_slot)

func _swap_cards(card: CardUI, new_slot: CardSlot) -> void:
	var old_slot = card_being_dragged.current_slot 
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	if new_slot.is_occupied():
		var card_in_target = new_slot.get_card()
		
		# Limpieza lógica
		new_slot.clear_slot()
		old_slot.clear_slot()
		
		# Intercambio cruzado
		old_slot.occupy_slot(card_in_target)
		new_slot.occupy_slot(card_being_dragged)
		
		# Animación de ambas cartas a la vez
		tween.tween_property(card_in_target, "global_position", old_slot.global_position, DEFAULT_CARD_MOVE_SPEED)
		tween.tween_property(card_being_dragged, "global_position", new_slot.global_position, DEFAULT_CARD_MOVE_SPEED)
	else:
		# Mover a un slot vacío
		old_slot.clear_slot()
		new_slot.occupy_slot(card_being_dragged)
		tween.tween_property(card_being_dragged, "global_position", new_slot.global_position, DEFAULT_CARD_MOVE_SPEED)

func _anchor_card_to_slot(card: CardUI, slot: CardSlot) -> void:
	card.is_in_hand = false
	card.is_in_slot = true
	card.current_slot = slot
	slot.occupy_slot(card)
	card.global_position = slot.global_position

func _perform_discard(card: CardUI, pile: DiscardPile) -> void:
	if card.is_in_slot and card.current_slot:
		card.current_slot.clear_slot()
	
	if card.is_in_hand:
		player_hand_reference.remove_card_from_hand(card)
	
	card.is_in_slot = false
	card.is_in_hand = false
	
	if pile:
		pile.discard_card(card)
	else:
		card.queue_free()

func return_card_to_origin() -> void:
	if card_being_dragged.is_in_slot and card_being_dragged.current_slot:
		card_being_dragged.global_position = card_being_dragged.current_slot.global_position
	else:
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)

# --- SEÑALES ---
func connect_card_signals(card: CardUI):
	card.hovered.connect(on_hovered_over_card)
	card.hovered_off.connect(on_hovered_off_card)

func on_hovered_over_card(card: CardUI):
	if !card_being_dragged:
		highlight_card(card, true)
		is_hovering_on_card = true
	
func on_hovered_off_card(card: CardUI):
	if !card_being_dragged:
		highlight_card(card, false)
		is_hovering_on_card = false
	
func highlight_card (card: CardUI, hovered: bool):
	card.scale = SCALE_HOV if hovered else SCALE_HOV_OFF
	card.z_index = 2 if hovered else 1

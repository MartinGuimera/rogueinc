class_name DiscardPile 
extends Node2D

# Array de recursos para la lógica de juego (Mazo/Reshuffle)
var discarded_resources: Array[CardData] = []
const CARD_DRAW_SPEED: float = 0.2

@onready var count_label: RichTextLabel = $RichTextLabel
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("discard_pile") # 
	_update_ui()

func discard_card(card: Node2D) -> void:
	if card is CardUI and card.card_data:
		discarded_resources.append(card.card_data)
		print("Guardado en descarte: ", card.card_data.card_name) 
	if card.has_node("Area2D"):
		card.get_node("Area2D").monitorable = false
		card.get_node("Area2D").monitoring = false

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "global_position", global_position, CARD_DRAW_SPEED)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(card, "scale", Vector2(0.5, 0.5), CARD_DRAW_SPEED)

	tween.set_parallel(false)
	tween.tween_callback(func():
		_update_ui()
		card.queue_free()
	)

func _update_ui() -> void:
	# Usamos discarded_resources como fuente de verdad para el contador
	count_label.text = str(discarded_resources.size())
	# La colisión del área de descarte siempre debe estar activa para recibir drag & drop
	collision_shape.disabled = false 
	sprite.visible = true
	count_label.visible = true

# Función para que el mazo recupere las cartas cuando se vacíe
func collect_discarded_cards() -> Array[CardData]:
	var to_return = discarded_resources.duplicate()
	discarded_resources.clear()
	_update_ui()
	return to_return

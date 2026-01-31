@tool
class_name CardData
extends Resource

# Enum to define the primary function of the card.
enum CardType {
	ATTACK,
	SHIELD,
	MINIGAME,
	EFFECT
}

@export var card_name: String = "Card Name"
@export_multiline var card_description: String = "Card Description"
@export var card_background: Texture2D
@export var card_art: Texture2D

@export_group("Gameplay")
@export var card_type: CardType = CardType.ATTACK
@export var base_value: float = 2
@export var cooldown: float = 2.3 

# For MINIGAME or EFFECT types, we might need a scene or a unique ID.
@export_group("Advanced")
@export var interactive_scene: PackedScene # e.g., for a coin-clicking minigame.

class_name Player
extends Entity

# Player-specific logic and properties will go here.
# For example, relics, gold, etc.

func _ready() -> void:
	super() # Call parent's _ready
	died.connect(_on_death)

func _on_death() -> void:
	print("Player has been defeated.")
	# Handle game over logic
	hide() # Or more complex animation

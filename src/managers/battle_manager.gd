class_name BattleManager
extends Node

# Signals to notify other parts of the game about state changes.
signal combat_phase_started
signal resolution_phase_started
signal battle_ended(was_player_victorious)

# Enum to manage the flow of battle.
enum BattleState {
	PREPARATION,
	COMBAT,
	RESOLUTION,
	REWARD
}

var current_state: BattleState = BattleState.PREPARATION
var player: Player
var current_enemies: Array[Enemy]

# "Pending Pools" for accumulating values during the COMBAT phase.
var player_pending_damage: float = 0.0
var player_pending_shield: float = 0.0

var enemy_pending_damage: float = 0.0
var enemy_pending_shield: float = 0.0

@export var combat_phase_duration: float = 10.0
var turn_timer: Timer

func _ready() -> void:
	# The turn timer will control the duration of the COMBAT phase.
	turn_timer = Timer.new()
	turn_timer.name = "TurnTimer"
	turn_timer.wait_time = combat_phase_duration
	turn_timer.one_shot = true
	turn_timer.timeout.connect(_on_turn_timer_timeout)
	add_child(turn_timer)

func start_battle(player_node: Player, enemies: Array[Enemy]) -> void:
	self.player = player_node
	self.current_enemies = enemies
	_enter_state(BattleState.PREPARATION)

func _enter_state(new_state: BattleState) -> void:
	current_state = new_state
	match current_state:
		BattleState.PREPARATION:
			# Player prepares their deck, places cards.
			# UI would show "Start Combat" button.
			pass
		BattleState.COMBAT:
			# Reset pending pools
			player_pending_damage = 0.0
			player_pending_shield = 0.0
			enemy_pending_damage = 0.0
			enemy_pending_shield = 0.0
			
			turn_timer.start()
			combat_phase_started.emit()
		BattleState.RESOLUTION:
			resolution_phase_started.emit()
			_resolve_combat()
		BattleState.REWARD:
			# Show reward screen, player chooses new cards/relics.
			battle_ended.emit(player.current_health > 0)
			pass

func _on_turn_timer_timeout() -> void:
	# Combat phase ends, move to resolution.
	_enter_state(BattleState.RESOLUTION)

# Called from CardUI instances via signal when their cooldown is complete.
func add_to_player_pool(card_data: CardData) -> void:
	if current_state != BattleState.COMBAT:
		return

	match card_data.card_type:
		CardData.CardType.ATTACK:
			player_pending_damage += card_data.base_value
		CardData.CardType.SHIELD:
			player_pending_shield += card_data.base_value
	
	# print("Player Pool: %s DMG, %s SHIELD" % [player_pending_damage, player_pending_shield])

func _resolve_combat() -> void:
	# --- Order of Operations ---
	# 1. Apply Shields
	player.add_shield(player_pending_shield)
	for enemy in current_enemies:
		# Assuming enemies can also have shields in the future.
		# enemy.add_shield(enemy_pending_shield)
		pass

	# 2. Calculate and Apply Damage
	# For simplicity, player attacks the first enemy.
	# A more complex targeting system would go here.
	if !current_enemies.is_empty():
		var target_enemy = current_enemies[0]
		target_enemy.take_damage(player_pending_damage)
	
	# 3. Resolve Effects (TBD)

	# Check for battle end conditions
	var surviving_enemies: Array[Enemy]
	for enemy in current_enemies:
		if is_instance_valid(enemy) and enemy.current_health > 0:
			surviving_enemies.append(enemy)
	current_enemies = surviving_enemies

	if player.current_health <= 0 or current_enemies.is_empty():
		_enter_state(BattleState.REWARD)
	else:
		_enter_state(BattleState.COMBAT)

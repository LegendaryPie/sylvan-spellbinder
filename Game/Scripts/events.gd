extends Node

# Settings
signal settings_updated(settings)

# Game state
signal game_started
signal game_paused
signal game_resumed
signal game_over(score)
signal level_completed(level)

# Player events
signal player_health_changed(current_health: int, max_health: int)
signal player_energy_changed(current_energy: float, max_energy: float)
signal player_died

# Enemy events
signal enemy_spawned(enemy)
signal enemy_died(enemy)
signal enemy_damaged(enemy, amount)

# Card events
signal card_drawn(card: CardResource, hand_index: int)
signal card_played(card_name: String, hand_index: int)
signal card_discarded(card)
signal card_clicked(hand_index: int)
signal view_deck_requested
signal view_discard_requested

# Targeting system signals
signal show_targeting_hint(spell_name: String)
signal targeting_cancelled

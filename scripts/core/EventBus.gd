extends Node
## EventBus (autoload) - plan.md Secao 47.
## Centraliza Signals para evitar dependencias excessivas entre sistemas.
## Uso: EventBus.player_died.emit(...), EventBus.kill_registered.connect(...)

signal player_died(victim_name: String, attacker_name: String)
signal enemy_died(victim_name: String, attacker_name: String)
signal weapon_fired(weapon_name: String)
signal weapon_reloaded(weapon_name: String)
signal weapon_switched(weapon_name: String)
signal loadout_changed
signal damage_received(target_name: String, amount: float, current_hp: float)
signal kill_registered(attacker_name: String, victim_name: String)
signal match_started
signal match_ended(winner_name: String)
signal player_respawned(player_name: String)
signal match_time_updated(time_left: float)

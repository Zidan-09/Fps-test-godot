extends Node
## DebugKeys - plan.md Secao 55 (ferramentas de desenvolvimento).
## F1: alterna debug (no DebugHUD) | F2: recarrega todas as armas | F3: cura total
## F4: adiciona kill | F5: reinicia a partida
## T: sofre 25 de dano (temporario, para testar morte sem inimigos).

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_guns"):
		_player_call("refill_all_weapons")
	elif event.is_action_pressed("debug_heal"):
		_player_call("heal_full")
	elif event.is_action_pressed("debug_kill"):
		var gm: Node = get_parent().get_node_or_null("GameManager")
		if gm != null and gm.has_method("register_kill"):
			gm.call("register_kill", "PLAYER", "DEBUG_TARGET")
	elif event.is_action_pressed("debug_restart"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("debug_hurt"):
		var player: Node = get_parent().get_node_or_null("Player")
		if player != null and player.has_method("take_damage"):
			var info := DamageInfo.make(25.0, "DEBUG", "debug", false, 0.0)
			player.call("take_damage", info)

func _player_call(method: String) -> void:
	var player: Node = get_parent().get_node_or_null("Player")
	if player != null and player.has_method(method):
		player.call(method)

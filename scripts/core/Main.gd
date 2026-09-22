extends Node3D
## Main - cena principal (plan.md Secao 49).
## Boot auto-diagnosticavel (regra do projeto): cada sistema ausente gera
## um aviso no Output, mas o jogo SEMPRE abre. Fluxo Fase 10:
## MENU PRINCIPAL -> LOADOUT -> PARTIDA -> PLACAR.
## Sem menu principal: loadout direto; sem loadout: partida com padrao.

func _ready() -> void:
	print("[BOOT] Main iniciada.")
	_check_node("Arena", true)
	_check_node("GameManager", true)
	_check_node("DebugHUD", false)
	_check_node("CombatHUD", false)
	_check_node("DebugKeys", false)
	_check_node("LoadoutMenu", false)
	_check_node("MatchEndScreen", false)
	_check_node("MainMenu", false)
	_check_node("PauseMenu", false)
	var audio: Node = get_node_or_null("/root/GameAudio")
	if audio == null:
		push_warning("[BOOT] Autoload GameAudio ausente; jogo segue sem som.")
	var player: Node3D = get_node_or_null("Player") as Node3D
	if player == null:
		push_error("[BOOT] Player nao encontrado; verifique scenes/player/Player.tscn.")
		return
	if player.get("health") == null:
		push_warning("[BOOT] Player sem Health; dano sera ignorado.")
	if player.has_method("get_weapon_list"):
		var arsenal: Array = player.call("get_weapon_list")
		if arsenal.is_empty():
			push_warning("[BOOT] Player sem armas; modo desarmado (só movimento).")
		else:
			print("[BOOT] Armas equipadas: %d." % arsenal.size())
	var spawn: Node3D = get_tree().get_first_node_in_group("player_spawn") as Node3D
	if spawn != null:
		player.global_position = spawn.global_position
		# Olha para o centro da arena.
		var target := Vector3(0, player.global_position.y, 0)
		if player.global_position.distance_to(target) > 0.1:
			player.look_at(target, Vector3.UP)
	else:
		push_warning("[BOOT] Spawn do grupo 'player_spawn' nao encontrado; Player fica na origem.")
	var mainmenu: Node = get_node_or_null("MainMenu")
	if mainmenu != null and mainmenu.has_method("show_menu"):
		mainmenu.call("show_menu")
		print("[BOOT] Menu principal: JOGAR abre o loadout; ESC pausa; F5 reinicia.")
		return
	var menu: Node = get_node_or_null("LoadoutMenu")
	if menu != null and menu.has_method("open_for_start") \
			and player.has_method("lock_controls"):
		menu.call("open_for_start")
		print("[BOOT] Loadout aberto: escolha as armas e inicie a partida.")
	else:
		if player.has_method("unlock_controls"):
			player.call("unlock_controls")
		# Sem menu nao ha quem inicie: partida direta (Fase 9).
		var gm: Node = get_node_or_null("GameManager")
		if gm != null and gm.has_method("start_match"):
			gm.call("start_match")
		print("[BOOT] Sem menu: partida direta. WASD move | mouse mira | botao esq. atira | R recarrega | 1/2 troca arma.")

func _check_node(node_name: String, required: bool) -> void:
	if get_node_or_null(node_name) == null:
		if required:
			push_error("[BOOT] No '%s' ausente na Main." % node_name)
		else:
			push_warning("[BOOT] No opcional '%s' ausente." % node_name)

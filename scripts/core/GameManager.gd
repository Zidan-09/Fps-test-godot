class_name GameManager
extends Node
## GameManager - plan.md Secao 46.
## Fase 9: fluxo MENU -> PLAYING -> MATCH_END, placar FFA completo e restart.
## O timer so corre em PLAYING; a partida comeca no "Iniciar" do loadout
## (ou direto, se nao houver menu). Restart recarrega a cena (reset total).

enum State { MENU, LOADING, PLAYING, PAUSED, MATCH_END }

@export var match_duration: float = GameConfig.MATCH_DURATION_SEC
@export var bot_count: int = GameConfig.BOT_COUNT
@export var bot_difficulty: int = 1 # 0 EASY, 1 NORMAL, 2 HARD (Secao 29)
@export var kill_limit: int = GameConfig.KILL_LIMIT

var current_state: State = State.MENU
var time_left: float = 0.0
var kills: int = 0
var deaths: int = 0
## Placar FFA (Secao 42): {nome: {"kills": int, "deaths": int}}.
## Inclui bots para o placar final ordenado; kills/deaths do player
## continuam espelhados nas vars acima para o HUD da Fase 8.
var scores: Dictionary = {}

func _ready() -> void:
	time_left = match_duration
	# Comeca em MENU com o timer congelado; quem inicia e o fluxo da Main
	# (loadout -> start_match) ou start_match direto sem menu.
	set_state(State.MENU)

func _process(delta: float) -> void:
	if current_state != State.PLAYING:
		return
	# Timer so corre em partida (Secao 46); congela em MENU/MATCH_END.
	if time_left > 0.0:
		time_left -= delta
		EventBus.match_time_updated.emit(time_left)
		if time_left <= 0.0:
			time_left = 0.0
			end_match("")

func set_state(new_state: State) -> void:
	current_state = new_state
	get_tree().paused = (new_state == State.PAUSED)

func pause_match() -> void:
	if current_state == State.PLAYING:
		set_state(State.PAUSED)

func resume_match() -> void:
	if current_state == State.PAUSED:
		set_state(State.PLAYING)

## Inicia a partida (chamado pelo loadout ou pela Main sem menu).
func start_match() -> void:
	if current_state == State.PLAYING:
		return
	time_left = match_duration
	set_state(State.PLAYING)
	EventBus.match_started.emit()
	print("[MATCH] Partida iniciada: %d combatentes, limite %d kills, %.0fs." \
		% [bot_count + 1, kill_limit, match_duration])

func register_kill(attacker_name: String, victim_name: String) -> void:
	register_combat_kill(attacker_name, victim_name)

## Kill generica do FFA (Fase 6+9): alimenta o placar de TODOS os
## combatentes (para o placar final ordenado) e o feed; o HUD do player
## usa kills/deaths, que so contam as suas (Secao 42).
## Suicidio conta death sem kill; alvos de debug nao entram no placar.
func register_combat_kill(attacker_name: String, victim_name: String) -> void:
	EventBus.kill_registered.emit(attacker_name, victim_name)
	# Treta fora da partida (bots brigando no menu, fundo do placar final):
	# alimenta o feed, mas nao o placar. Placar so conta em PLAYING.
	if current_state != State.PLAYING:
		return
	if not str(victim_name).begins_with("DEBUG_"):
		_bump_score(victim_name, false)
	if attacker_name != victim_name and not str(attacker_name).begins_with("DEBUG_"):
		_bump_score(attacker_name, true)
	if attacker_name == FPSPlayer.PLAYER_NAME and attacker_name != victim_name:
		kills += 1
		if kills >= kill_limit and current_state == State.PLAYING:
			end_match(attacker_name)
	if victim_name == FPSPlayer.PLAYER_NAME:
		deaths += 1

func _bump_score(combatant: String, was_kill: bool) -> void:
	if not scores.has(combatant):
		scores[combatant] = {"kills": 0, "deaths": 0}
	if was_kill:
		scores[combatant]["kills"] = int(scores[combatant]["kills"]) + 1
	else:
		scores[combatant]["deaths"] = int(scores[combatant]["deaths"]) + 1

## Placar ordenado por kills (desempate: menos deaths). So apresentacao,
## sem sistema competitivo (Secao 42). Sempre inclui o player.
func get_standings() -> Array:
	if not scores.has(FPSPlayer.PLAYER_NAME):
		scores[FPSPlayer.PLAYER_NAME] = {"kills": kills, "deaths": deaths}
	else:
		scores[FPSPlayer.PLAYER_NAME]["kills"] = kills
		scores[FPSPlayer.PLAYER_NAME]["deaths"] = deaths
	var table: Array = []
	for combatant in scores:
		table.append({"name": str(combatant),
			"kills": int(scores[combatant]["kills"]),
			"deaths": int(scores[combatant]["deaths"])})
	table.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["kills"]) != int(b["kills"]):
			return int(a["kills"]) > int(b["kills"])
		return int(a["deaths"]) < int(b["deaths"]))
	return table

func get_leader_name() -> String:
	var table := get_standings()
	if table.is_empty():
		return FPSPlayer.PLAYER_NAME
	return str(table[0]["name"])

func register_death() -> void:
	deaths += 1

func end_match(winner_name: String) -> void:
	if current_state == State.MATCH_END:
		return
	if str(winner_name).is_empty() or winner_name == "TIME_UP":
		winner_name = get_leader_name()
	set_state(State.MATCH_END)
	var p: Node = get_parent().get_node_or_null("Player")
	if p != null and p.has_method("lock_controls"):
		p.call("lock_controls")
	print("[MATCH] Partida encerrada. Vencedor: %s." % winner_name)
	EventBus.match_ended.emit(winner_name)

## Jogar novamente (Secao 56, item 22): recarrega a cena para reset total
## de player, bots, timer e placar. Mesmo mecanismo do F5 de debug.
func restart_match() -> void:
	get_tree().reload_current_scene()

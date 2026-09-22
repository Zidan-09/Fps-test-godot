extends CanvasLayer
## CombatHUD completo - plan.md Secoes 39/40/41/42 (Fase 8).
## Mostra: placar KILLS/DEATHS (topo-esq), timer (topo-centro), kill feed
## (topo-dir), crosshair dinamica (centro), HP com cor (inf-esq), arma +
## municao + barra de reload (inf-dir), hitmarker (41), flash de dano,
## countdown de respawn e aviso de fim de partida.
## Tudo criado em codigo: nenhum asset externo, nunca quebra sem referencia.

const FEED_MAX := 5
const FEED_LIFETIME := 4.0

var _cross_lines: Array[ColorRect] = []
var _hitmarker: Label
var _hp_bar: ProgressBar
var _hp_fill: StyleBoxFlat
var _hp_label: Label
var _ammo_label: Label
var _weapon_label: Label
var _reload_bar: ProgressBar
var _score_label: Label
var _timer_label: Label
var _feed_box: VBoxContainer
var _feed_entries: Array = [] # {node: Label, left: float}
var _message_label: Label
var _end_label: Label
var _death_overlay: ColorRect
var _death_label: Label
var _vignette: ColorRect

var _hitmarker_timer: float = 0.0
var _message_timer: float = 0.0
var _poll: float = 0.0
var _low_hp: bool = false
var _time_accum: float = 0.0
var _player: Node
var _gm: Node
var _weapon: Weapon
var _dead: bool = false

func _ready() -> void:
	_build_widgets()
	_vignette.modulate.a = 0.0
	_death_overlay.visible = false
	_message_label.modulate.a = 0.0
	_end_label.visible = false
	call_deferred("_connect_all")

func _build_widgets() -> void:
	_build_crosshair()
	_hitmarker = _make_label("X", 26, Color.WHITE)
	_hitmarker.set_anchors_preset(Control.PRESET_CENTER)
	_hitmarker.position += Vector2(14, -24)
	_hitmarker.modulate.a = 0.0
	add_child(_hitmarker)

	# Placar (Secao 39/42): topo-esquerda.
	_score_label = _make_label("KILLS 0   DEATHS 0", 18, Color.WHITE)
	_score_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_score_label.position = Vector2(16, 12)
	add_child(_score_label)

	# Timer (Secao 39): topo-centro.
	_timer_label = _make_label("--:--", 24, Color.WHITE)
	_timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_timer_label.position = Vector2(-40, 10)
	add_child(_timer_label)

	# Kill feed (Secao 40): topo-direita, some apos FEED_LIFETIME.
	_feed_box = VBoxContainer.new()
	_feed_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_feed_box.position = Vector2(-320, 12)
	_feed_box.custom_minimum_size = Vector2(300, 20)
	_feed_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(_feed_box)

	# HP (Secao 39): barra com cor por faixa + numero.
	_hp_fill = StyleBoxFlat.new()
	_hp_fill.bg_color = Color(0.25, 0.85, 0.3)
	_hp_fill.corner_radius_top_left = 3
	_hp_fill.corner_radius_top_right = 3
	_hp_fill.corner_radius_bottom_left = 3
	_hp_fill.corner_radius_bottom_right = 3
	_hp_bar = ProgressBar.new()
	_hp_bar.min_value = 0.0
	_hp_bar.max_value = 100.0
	_hp_bar.value = 100.0
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(220, 18)
	_hp_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hp_bar.position = Vector2(16, -60)
	_hp_bar.add_theme_stylebox_override("fill", _hp_fill)
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_bar)

	_hp_label = _make_label("100", 18, Color.WHITE)
	_hp_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hp_label.position = Vector2(16, -88)
	add_child(_hp_label)

	# Arma + municao + reload (Secao 23/39): inferior-direita.
	_weapon_label = _make_label("", 16, Color(0.75, 0.75, 0.78))
	_weapon_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_weapon_label.position = Vector2(-220, -116)
	_weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_weapon_label.custom_minimum_size = Vector2(200, 22)
	add_child(_weapon_label)

	_ammo_label = _make_label("", 26, Color.WHITE)
	_ammo_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_ammo_label.position = Vector2(-220, -92)
	_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ammo_label.custom_minimum_size = Vector2(200, 34)
	add_child(_ammo_label)

	_reload_bar = ProgressBar.new()
	_reload_bar.min_value = 0.0
	_reload_bar.max_value = 100.0
	_reload_bar.value = 0.0
	_reload_bar.show_percentage = false
	_reload_bar.custom_minimum_size = Vector2(200, 6)
	_reload_bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_reload_bar.position = Vector2(-220, -56)
	_reload_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_reload_bar)

	_message_label = _make_label("", 20, Color(1.0, 0.85, 0.3))
	_message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_message_label.position = Vector2(-140, 60)
	add_child(_message_label)

	_end_label = _make_label("", 30, Color(1.0, 0.85, 0.3))
	_end_label.set_anchors_preset(Control.PRESET_CENTER)
	_end_label.position = Vector2(-220, -80)
	_end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_label.custom_minimum_size = Vector2(440, 90)
	add_child(_end_label)

	_vignette = ColorRect.new()
	_vignette.color = Color(0.8, 0.05, 0.05, 0.45)
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)

	_death_overlay = ColorRect.new()
	_death_overlay.color = Color(0.05, 0.0, 0.0, 0.75)
	_death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_death_overlay)

	_death_label = _make_label("ELIMINADO - respawnando...", 32, Color(1.0, 0.3, 0.25))
	_death_label.set_anchors_preset(Control.PRESET_CENTER)
	_death_label.position = Vector2(-260, -30)
	_death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_label.custom_minimum_size = Vector2(520, 44)
	_death_overlay.add_child(_death_label)

## Crosshair em 4 linhas: gap abre com spread + movimento, some no ADS.
func _build_crosshair() -> void:
	_cross_lines.clear()
	for i in 4:
		var line := ColorRect.new()
		line.color = Color(1, 1, 1, 0.9)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.set_anchors_preset(Control.PRESET_CENTER)
		add_child(line)
		_cross_lines.append(line)
	_layout_crosshair(8.0)

func _layout_crosshair(gap: float) -> void:
	if _cross_lines.size() < 4:
		return
	var length := 10.0
	var thick := 2.0
	# Ordem: cima, baixo, esquerda, direita.
	_cross_lines[0].position = Vector2(-thick * 0.5, -gap - length)
	_cross_lines[0].size = Vector2(thick, length)
	_cross_lines[1].position = Vector2(-thick * 0.5, gap)
	_cross_lines[1].size = Vector2(thick, length)
	_cross_lines[2].position = Vector2(-gap - length, -thick * 0.5)
	_cross_lines[2].size = Vector2(length, thick)
	_cross_lines[3].position = Vector2(gap, -thick * 0.5)
	_cross_lines[3].size = Vector2(length, thick)

func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

## Audio opcional (Secao 52): sem GameAudio, o HUD segue mudo sem quebrar.
func _sfx(method_name: String) -> void:
	var audio: Node = get_node_or_null("/root/GameAudio")
	if audio != null and audio.has_method(method_name):
		audio.call(method_name)

func _connect_all() -> void:
	_player = get_parent().get_node_or_null("Player")
	_gm = get_parent().get_node_or_null("GameManager")
	if _player != null and _player.get("health") != null:
		var hp: Health = _player.get("health") as Health
		hp.health_changed.connect(_on_hp_changed)
		_on_hp_changed(hp.current, hp.max_health)
	_sync_active_weapon()
	_connect_hitmarkers()
	_refresh_ammo()
	_refresh_score()
	_refresh_timer()
	EventBus.weapon_switched.connect(_on_weapon_switched)
	EventBus.loadout_changed.connect(_on_loadout_changed)
	EventBus.damage_received.connect(_on_damage_received)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.kill_registered.connect(_on_kill_registered)
	EventBus.match_time_updated.connect(_on_match_time_updated)
	EventBus.match_ended.connect(_on_match_ended)

func _process(delta: float) -> void:
	_time_accum += delta
	_tick_feed(delta)
	_poll -= delta
	if _poll <= 0.0:
		_poll = 0.1
		_refresh_ammo() # polling: imune a reconexoes apos troca de loadout
		_refresh_score()
		_refresh_reload()
		_refresh_respawn_countdown()
	_update_crosshair()
	if _hitmarker_timer > 0.0:
		_hitmarker_timer -= delta
		if _hitmarker_timer <= 0.0:
			_hitmarker.modulate.a = 0.0
	if _message_timer > 0.0:
		_message_timer -= delta
		if _message_timer <= 0.0:
			_message_label.modulate.a = 0.0
	_update_vignette(delta)

func _update_vignette(delta: float) -> void:
	if _low_hp and not _dead:
		# HP baixo: pulsacao vermelha continua ate regenerar (Secao 39).
		_vignette.modulate.a = maxf(_vignette.modulate.a - delta * 1.5,
			0.22 + 0.12 * sin(_time_accum * 5.0))
	elif _vignette.modulate.a > 0.0:
		_vignette.modulate.a = maxf(_vignette.modulate.a - delta * 1.5, 0.0)

func _on_hp_changed(current: float, maximum: float) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_hp_label.text = "%d" % int(ceili(current))
	var frac := clampf(current / maxf(maximum, 1.0), 0.0, 1.0)
	if frac > 0.55:
		_hp_fill.bg_color = Color(0.25, 0.85, 0.3)
	elif frac > 0.28:
		_hp_fill.bg_color = Color(0.95, 0.8, 0.2)
	else:
		_hp_fill.bg_color = Color(0.9, 0.2, 0.15)
	_low_hp = current <= 30.0 and current > 0.0

func _sync_active_weapon() -> void:
	if _player != null and _player.has_method("get_active_weapon"):
		_weapon = _player.call("get_active_weapon") as Weapon

func _on_weapon_switched(_weapon_name: String) -> void:
	_sync_active_weapon()
	_refresh_ammo()

## Hitmarker reconecta a cada loadout (conexoes antigas morrem com a arma).
func _connect_hitmarkers() -> void:
	if _player == null or not _player.has_method("get_weapon_list"):
		return
	var arsenal: Array = _player.call("get_weapon_list")
	for w in arsenal:
		var wpn := w as Weapon
		if wpn == null:
			continue
		if not wpn.hit_confirmed.is_connected(_on_hit_confirmed):
			wpn.hit_confirmed.connect(_on_hit_confirmed)

func _on_loadout_changed() -> void:
	_sync_active_weapon()
	_connect_hitmarkers()
	_refresh_ammo()

func _refresh_ammo() -> void:
	if _weapon != null and is_instance_valid(_weapon) and _weapon.data != null:
		_weapon_label.text = _weapon.data.weapon_name
		var txt := "%d / %d" % [_weapon.mag, _weapon.reserve]
		if _weapon.is_reloading():
			txt += "  (RECARREGANDO)"
		_ammo_label.text = txt
	else:
		_weapon_label.text = "--"
		_ammo_label.text = "-- / --"

func _refresh_reload() -> void:
	if _weapon != null and is_instance_valid(_weapon) and _weapon.is_reloading():
		_reload_bar.value = _weapon.reload_progress() * 100.0
	else:
		_reload_bar.value = 0.0

## Secao 42: placar puxado do GameManager (kills so contam as suas, Fase 6).
func _refresh_score() -> void:
	if _gm != null and _gm.get("kills") != null and _gm.get("deaths") != null:
		_score_label.text = "KILLS %d   DEATHS %d" % [int(_gm.get("kills")), int(_gm.get("deaths"))]

func _refresh_timer() -> void:
	if _gm != null and _gm.get("time_left") != null:
		_on_match_time_updated(float(_gm.get("time_left")))

func _on_match_time_updated(time_left: float) -> void:
	var total := maxi(int(ceili(time_left)), 0)
	_timer_label.text = "%02d:%02d" % [total / 60, total % 60]
	_timer_label.add_theme_color_override("font_color",
		Color(1.0, 0.3, 0.25) if total <= 30 else Color.WHITE)

## Secao 40: feed com as kills do FFA, destaque quando voce participa.
func _on_kill_registered(attacker_name: String, victim_name: String) -> void:
	_refresh_score()
	var entry := _make_label("%s  >  %s" % [attacker_name, victim_name], 15,
		Color(1.0, 0.85, 0.3) if attacker_name == FPSPlayer.PLAYER_NAME
		else (Color(1.0, 0.45, 0.4) if victim_name == FPSPlayer.PLAYER_NAME
		else Color(0.75, 0.75, 0.75)))
	entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_feed_box.add_child(entry)
	_feed_box.move_child(entry, 0)
	_feed_entries.push_front({"node": entry, "left": FEED_LIFETIME})
	while _feed_entries.size() > FEED_MAX:
		var old: Dictionary = _feed_entries.pop_back()
		if is_instance_valid(old["node"]):
			(old["node"] as Node).queue_free()

func _tick_feed(delta: float) -> void:
	for i in range(_feed_entries.size() - 1, -1, -1):
		var e: Dictionary = _feed_entries[i]
		e["left"] = float(e["left"]) - delta
		var node := e["node"] as Label
		if not is_instance_valid(node):
			_feed_entries.remove_at(i)
			continue
		if float(e["left"]) <= 0.0:
			node.queue_free()
			_feed_entries.remove_at(i)
		elif float(e["left"]) < 1.0:
			node.modulate.a = clampf(float(e["left"]), 0.0, 1.0)

## Crosshair abre com spread da arma + velocidade; some no ADS/morte/menu.
func _update_crosshair() -> void:
	var show := not _dead and _player != null and _player.has_method("is_targetable") \
		and bool(_player.call("is_targetable"))
	var ads := _player != null and _player.has_method("is_ads") \
		and bool(_player.call("is_ads"))
	if not show or ads:
		for line in _cross_lines:
			line.visible = false
		return
	var gap := 8.0
	if _weapon != null and is_instance_valid(_weapon) and _weapon.data != null:
		gap += _weapon.data.spread_hip_deg * 1.5
	if _player is CharacterBody3D:
		var planar := Vector2((_player as CharacterBody3D).velocity.x,
			(_player as CharacterBody3D).velocity.z).length()
		gap += planar * 0.8
	for line in _cross_lines:
		line.visible = true
	_layout_crosshair(clampf(gap, 6.0, 40.0))

## Secao 41/52: hitmarker normal, amarelo no headshot, vermelho na kill.
func _on_hit_confirmed(killed: bool, headshot: bool) -> void:
	if killed:
		_hitmarker.add_theme_color_override("font_color", Color(1.0, 0.2, 0.15))
		_hitmarker.add_theme_font_size_override("font_size", 32)
		_sfx("play_kill")
	elif headshot:
		_hitmarker.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		_hitmarker.add_theme_font_size_override("font_size", 28)
		_sfx("play_headshot")
	else:
		_hitmarker.add_theme_color_override("font_color", Color.WHITE)
		_hitmarker.add_theme_font_size_override("font_size", 26)
		_sfx("play_hit")
	_hitmarker.modulate.a = 1.0
	_hitmarker_timer = 0.25 if not killed else 0.5

func _on_damage_received(target_name: String, _amount: float, _current_hp: float) -> void:
	if target_name == FPSPlayer.PLAYER_NAME:
		_vignette.modulate.a = 0.85

func _on_enemy_died(victim_name: String, _attacker_name: String) -> void:
	_message_label.text = "%s ELIMINADO" % victim_name
	_message_label.modulate.a = 1.0
	_message_timer = 1.2

func _on_player_died(_victim: String, _attacker: String) -> void:
	_dead = true
	_death_overlay.visible = true
	_sfx("play_death")
	_refresh_respawn_countdown()

func _on_player_respawned(_player_name: String) -> void:
	_dead = false
	_death_overlay.visible = false
	_vignette.modulate.a = 0.0

func _refresh_respawn_countdown() -> void:
	if not _dead or _player == null or not _player.has_method("get_respawn_left"):
		return
	_death_label.text = "ELIMINADO - respawn em %.1f" % _player.call("get_respawn_left")

## Aviso simples apenas se a tela de placar (Fase 9) nao existir.
func _on_match_ended(winner_name: String) -> void:
	if get_parent().get_node_or_null("MatchEndScreen") != null:
		return
	_end_label.text = "PARTIDA ENCERRADA\nVencedor: %s" % winner_name
	_end_label.visible = true

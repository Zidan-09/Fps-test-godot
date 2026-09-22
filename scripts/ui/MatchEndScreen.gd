extends CanvasLayer
## MatchEndScreen - placar final do Deathmatch (plan.md Secao 42, Fase 9).
## Ouve match_ended e mostra: titulo, vencedor, tabela RANK/PLAYER/KILLS/
## DEATHS ordenada por kills com o player destacado, e JOGAR NOVAMENTE.
## Criada em codigo (sem assets); se o GameManager faltar, nunca abre.

var _bg: ColorRect
var _title_label: Label
var _winner_label: Label
var _rows_box: VBoxContainer
var _restart_button: Button

func _ready() -> void:
	_build()
	_bg.hide()
	EventBus.match_ended.connect(_on_match_ended)

func _build() -> void:
	_bg = ColorRect.new()
	_bg.name = "MatchEndBG"
	_bg.color = Color(0.02, 0.03, 0.05, 0.93)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	_title_label = _label("PARTIDA ENCERRADA", 30, Color(1.0, 0.85, 0.3))
	vbox.add_child(_title_label)
	_winner_label = _label("", 18, Color.WHITE)
	vbox.add_child(_winner_label)
	vbox.add_child(_label("RANK   JOGADOR   KILLS   DEATHS", 15, Color(0.7, 0.7, 0.75)))
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 2)
	vbox.add_child(_rows_box)
	_restart_button = Button.new()
	_restart_button.text = "JOGAR NOVAMENTE (Enter)"
	_restart_button.custom_minimum_size = Vector2(0, 52)
	_restart_button.pressed.connect(_on_restart_pressed)
	vbox.add_child(_restart_button)

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

func _on_match_ended(winner_name: String) -> void:
	var gm: Node = get_parent().get_node_or_null("GameManager")
	var table: Array = []
	if gm != null and gm.has_method("get_standings"):
		table = gm.call("get_standings")
	if table.is_empty():
		return # sem placar, sem tela: HUD da Fase 8 assume o aviso
	for child in _rows_box.get_children():
		child.queue_free()
	if winner_name == FPSPlayer.PLAYER_NAME:
		_title_label.text = "VITORIA!"
		_winner_label.text = "Voce venceu a partida."
	else:
		_title_label.text = "PARTIDA ENCERRADA"
		_winner_label.text = "Vencedor: %s" % winner_name
	var rank := 1
	for row in table:
		var d: Dictionary = row
		var me := str(d.get("name", "?")) == FPSPlayer.PLAYER_NAME
		var line := _label("#%d   %s   %d   %d" % [rank,
			str(d.get("name", "?")), int(d.get("kills", 0)), int(d.get("deaths", 0))],
			17, Color(1.0, 0.85, 0.3) if me else Color(0.85, 0.85, 0.88))
		_rows_box.add_child(line)
		rank += 1
		if rank > 8:
			break
	_bg.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_restart_button.grab_focus()

func _on_restart_pressed() -> void:
	var gm: Node = get_parent().get_node_or_null("GameManager")
	if gm != null and gm.has_method("restart_match"):
		gm.call("restart_match")
	else:
		get_tree().reload_current_scene()

extends CanvasLayer
## LoadoutMenu - fatia funcional da Secao 44 (telas completas na Fase 10).
## Permite escolher primaria/secundaria com stats visiveis e iniciar a partida.
## Fase 10: abre via menu principal (JOGAR) ou tecla L; comeca escondido e
## a Main orquestra. Se nada o chamar, a Main inicia direto com padrao.

const PRIMARIES: Array = [
	{"label": "AR-01 Raptor", "sub": "Assault Rifle", "path": "res://resources/weapons/AR01_Raptor.tres"},
	{"label": "SMG-07 Wasp", "sub": "SMG", "path": "res://resources/weapons/SMG07_Wasp.tres"},
	{"label": "SG-12 Hammer", "sub": "Shotgun", "path": "res://resources/weapons/SG12_Hammer.tres"},
	{"label": "SR-01 Sentinel", "sub": "Sniper", "path": "res://resources/weapons/SR01_Sentinel.tres"},
]
const SECONDARIES: Array = [
	{"label": "PX-9 Viper", "sub": "Pistol", "path": "res://resources/weapons/PX9_Viper.tres"},
]

var _sel_primary: int = 0
var _sel_secondary: int = 0
var _started: bool = false
var _bg: ColorRect
var _primary_group := ButtonGroup.new()
var _secondary_group := ButtonGroup.new()

func _ready() -> void:
	_build()
	_bg.hide() # abre via menu principal (JOGAR) ou tecla L

func _get_player() -> Node:
	return get_parent().get_node_or_null("Player")

## Chamado pela Main no boot.
func open_for_start() -> void:
	_started = false
	_bg.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var p := _get_player()
	if p != null and p.has_method("lock_controls"):
		p.call("lock_controls")

func is_open() -> bool:
	return _bg.visible

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("loadout") and _started:
		if is_open():
			_confirm()
		else:
			_reopen()
	elif is_open() and not _started and event.is_action_pressed("ui_accept"):
		_confirm()

func _reopen() -> void:
	_bg.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var p := _get_player()
	if p != null and p.has_method("lock_controls"):
		p.call("lock_controls")

func _confirm() -> void:
	var p := _get_player()
	var prim: String = str(PRIMARIES[_sel_primary]["path"])
	var sec: String = str(SECONDARIES[_sel_secondary]["path"])
	if p != null and p.has_method("set_loadout"):
		# call() passa cada argumento apos o nome: o array vai DIRETO
		# (embrulhar de novo ([[prim, sec]]) entrega um array-dentro-de-array
		# e o loadout fica vazio = jogador desarmado, sem tiro).
		if not bool(p.call("set_loadout", [prim, sec])):
			push_warning("[Loadout] Falha ao aplicar; loadout anterior mantido.")
	if p != null and p.has_method("unlock_controls"):
		p.call("unlock_controls")
	# Fase 9: confirmar o loadout INICIA a partida (timer + estado PLAYING).
	var gm: Node = get_parent().get_node_or_null("GameManager")
	if gm != null and gm.has_method("start_match"):
		gm.call("start_match")
	_bg.hide()
	_started = true

func _build() -> void:
	_bg = ColorRect.new()
	_bg.name = "LoadoutBG"
	_bg.color = Color(0.02, 0.03, 0.05, 0.92)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	vbox.add_child(_title("LOADOUT"))
	vbox.add_child(_title("PRIMARIA", 16))
	for i in PRIMARIES.size():
		var b := _option_button(str(PRIMARIES[i]["label"]), str(PRIMARIES[i]["sub"]),
			str(PRIMARIES[i]["path"]), _primary_group, i == _sel_primary)
		b.toggled.connect(_on_primary_toggled.bind(i))
		vbox.add_child(b)
	vbox.add_child(_title("SECUNDARIA", 16))
	for i in SECONDARIES.size():
		var b2 := _option_button(str(SECONDARIES[i]["label"]), str(SECONDARIES[i]["sub"]),
			str(SECONDARIES[i]["path"]), _secondary_group, i == _sel_secondary)
		b2.toggled.connect(_on_secondary_toggled.bind(i))
		vbox.add_child(b2)
	var start := Button.new()
	start.text = "INICIAR PARTIDA (Enter)"
	start.custom_minimum_size = Vector2(0, 48)
	start.pressed.connect(_confirm)
	vbox.add_child(start)
	vbox.add_child(_hint("L reabre o loadout durante a partida."))

func _title(text: String, size: int = 26) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	return l

func _hint(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	return l

func _stats_line(path: String) -> String:
	if not ResourceLoader.exists(path):
		return "ausente"
	var data := load(path) as WeaponData
	if data == null:
		return "invalida"
	return "Dano %d | %drpm | %d balas | %dm" % [int(data.damage),
		int(data.fire_rate), data.magazine_size, int(data.max_range)]

func _option_button(label: String, sub: String, path: String, group: ButtonGroup, pressed: bool) -> Button:
	var b := Button.new()
	b.text = "%s (%s)\n%s" % [label, sub, _stats_line(path)]
	b.toggle_mode = true
	b.button_pressed = pressed
	b.button_group = group
	b.custom_minimum_size = Vector2(0, 56)
	if not ResourceLoader.exists(path):
		b.disabled = true
	return b

func _on_primary_toggled(pressed_on: bool, idx: int) -> void:
	if pressed_on:
		_sel_primary = idx

func _on_secondary_toggled(pressed_on: bool, idx: int) -> void:
	if pressed_on:
		_sel_secondary = idx

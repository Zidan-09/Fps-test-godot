extends CanvasLayer
## PauseMenu - tela de pausa (plan.md Secao 45, Fase 10).
## ESC em partida pausa tudo (gameplay, IA, timers via get_tree().paused);
## opcoes: CONTINUAR, CONFIGURACOES, REINICIAR, MENU PRINCIPAL (recarrega
## a cena, que abre no menu). Usa _input para consumir o ESC antes do
## Player, sem conflito com o alternador de mouse. Criado em codigo.

const SETTINGS_SCRIPT := "res://scripts/ui/SettingsPanel.gd"

var _bg: ColorRect
var _settings: PanelContainer
var _resume_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_bg.hide()

func _gm() -> Node:
	return get_parent().get_node_or_null("GameManager")

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	var gm := _gm()
	if gm == null or gm.get("current_state") == null:
		return
	var state: int = int(gm.get("current_state"))
	# PLAYING = 2, PAUSED = 3 (GameManager.State). Comparar por int evita
	# acoplamento rigido com o enum e nunca quebra se ele mudar de ordem.
	if state == 2 and not _bg.visible:
		_pause()
		get_viewport().set_input_as_handled()
	elif state == 3 and _bg.visible:
		_resume()
		get_viewport().set_input_as_handled()

func is_open() -> bool:
	return _bg.visible

func _build() -> void:
	_bg = ColorRect.new()
	_bg.name = "PauseBG"
	_bg.color = Color(0.02, 0.03, 0.05, 0.88)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	var title := Label.new()
	title.text = "PAUSADO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)
	_resume_button = _menu_button(vbox, "CONTINUAR (ESC)")
	_resume_button.pressed.connect(_resume)
	_menu_button(vbox, "CONFIGURACOES").pressed.connect(_on_settings)
	_menu_button(vbox, "REINICIAR PARTIDA").pressed.connect(_on_restart)
	_menu_button(vbox, "MENU PRINCIPAL").pressed.connect(_on_menu)
	if ResourceLoader.exists(SETTINGS_SCRIPT):
		var scr := load(SETTINGS_SCRIPT) as Script
		if scr != null:
			_settings = scr.new() as PanelContainer
			_settings.hide()
			vbox.add_child(_settings)

func _menu_button(parent: Control, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	parent.add_child(b)
	return b

func _click() -> void:
	var audio: Node = get_node_or_null("/root/GameAudio")
	if audio != null and audio.has_method("play_ui"):
		audio.call("play_ui")

func _pause() -> void:
	var gm := _gm()
	if gm != null and gm.has_method("pause_match"):
		gm.call("pause_match")
	_bg.show()
	if _settings != null:
		_settings.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_resume_button.grab_focus()

func _resume() -> void:
	_click()
	_bg.hide()
	var gm := _gm()
	if gm != null and gm.has_method("resume_match"):
		gm.call("resume_match")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_settings() -> void:
	_click()
	_resume_button.release_focus()
	if _settings != null:
		_settings.visible = not _settings.visible

func _on_restart() -> void:
	_click()
	get_tree().paused = false
	var gm := _gm()
	if gm != null and gm.has_method("restart_match"):
		gm.call("restart_match")
	else:
		get_tree().reload_current_scene()

func _on_menu() -> void:
	_click()
	# Boot abre no menu principal: recarregar e voltar ao menu.
	get_tree().paused = false
	get_tree().reload_current_scene()

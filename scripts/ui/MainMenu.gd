extends CanvasLayer
## MainMenu - menu principal (plan.md Secao 43, Fase 10).
## JOGAR abre o loadout, CONFIGURACOES embute o SettingsPanel, SAIR fecha.
## Chamado pela Main no boot; se o loadout faltar, inicia direto com padrao.
## Criado em codigo, sem assets.

const SETTINGS_SCRIPT := "res://scripts/ui/SettingsPanel.gd"

var _bg: ColorRect
var _settings: PanelContainer
var _play_button: Button

func _ready() -> void:
	_build()
	_bg.hide()

## Chamado pela Main no boot (Fase 9/10).
func show_menu() -> void:
	_bg.show()
	if _settings != null:
		_settings.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var p := get_parent().get_node_or_null("Player")
	if p != null and p.has_method("lock_controls"):
		p.call("lock_controls")
	_play_button.grab_focus()

func is_open() -> bool:
	return _bg.visible

func _build() -> void:
	_bg = ColorRect.new()
	_bg.name = "MainMenuBG"
	_bg.color = Color(0.02, 0.03, 0.05, 0.94)
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
	title.text = "PROTOTIPO FPS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)
	var sub := Label.new()
	sub.text = "Deathmatch 1x7 contra bots"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	vbox.add_child(sub)
	_play_button = _menu_button(vbox, "JOGAR")
	_play_button.pressed.connect(_on_play)
	_menu_button(vbox, "CONFIGURACOES").pressed.connect(_on_settings)
	_menu_button(vbox, "SAIR").pressed.connect(_on_quit)
	if ResourceLoader.exists(SETTINGS_SCRIPT):
		var scr := load(SETTINGS_SCRIPT) as Script
		if scr != null:
			_settings = scr.new() as PanelContainer
			_settings.hide()
			vbox.add_child(_settings)

func _menu_button(parent: Control, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	parent.add_child(b)
	return b

func _click() -> void:
	var audio: Node = get_node_or_null("/root/GameAudio")
	if audio != null and audio.has_method("play_ui"):
		audio.call("play_ui")

func _on_play() -> void:
	_click()
	var menu: Node = get_parent().get_node_or_null("LoadoutMenu")
	if menu != null and menu.has_method("open_for_start"):
		_bg.hide()
		menu.call("open_for_start")
	else:
		# Sem loadout: partida direta com padrao (mesmo fallback da Main).
		_bg.hide()
		var p := get_parent().get_node_or_null("Player")
		if p != null and p.has_method("unlock_controls"):
			p.call("unlock_controls")
		var gm: Node = get_parent().get_node_or_null("GameManager")
		if gm != null and gm.has_method("start_match"):
			gm.call("start_match")

func _on_settings() -> void:
	_click()
	if _settings != null:
		_settings.visible = not _settings.visible

func _on_quit() -> void:
	_click()
	get_tree().quit()

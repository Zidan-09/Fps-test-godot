extends PanelContainer
## SettingsPanel - configuracoes (Secao 43/45, Fase 10).
## Reusado pelo menu principal e pela pausa. Salva em user://settings.cfg
## e aplica ao vivo: sensibilidade e FOV do player, volumes master/SFX,
## sombras e efeitos de camera. Tudo com guards: sem player/audio/luz por
## perto, apenas salva para a proxima sessao (nunca quebra).

const SAVE_PATH := "user://settings.cfg"

var _sens: HSlider
var _fov: HSlider
var _master: HSlider
var _sfx: HSlider
var _shadows: CheckButton
var _camfx: CheckButton
var _loading: bool = true

func _ready() -> void:
	_build()
	_load_and_apply()

func _build() -> void:
	custom_minimum_size = Vector2(420, 0)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	var title := Label.new()
	title.text = "CONFIGURACOES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)
	_sens = _slider_row(vbox, "Sensibilidade do mouse", 20.0, 200.0, 100.0)
	_fov = _slider_row(vbox, "Campo de visao (FOV)", 60.0, 100.0, 75.0)
	_master = _slider_row(vbox, "Volume geral", 0.0, 100.0, 100.0)
	_sfx = _slider_row(vbox, "Volume de efeitos", 0.0, 100.0, 100.0)
	_shadows = _check_row(vbox, "Sombras", true)
	_camfx = _check_row(vbox, "Efeitos de camera (bob/shake)", true)

func _slider_row(parent: Control, text: String, min_v: float, max_v: float, def: float) -> HSlider:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.85, 0.85, 0.88))
	parent.add_child(l)
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = 1.0
	s.value = def
	s.custom_minimum_size = Vector2(0, 24)
	s.value_changed.connect(_on_any_changed)
	parent.add_child(s)
	return s

func _check_row(parent: Control, text: String, def: bool) -> CheckButton:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = def
	c.add_theme_font_size_override("font_size", 15)
	c.toggled.connect(_on_any_changed)
	parent.add_child(c)
	return c

func _on_any_changed(_value: Variant) -> void:
	if _loading:
		return
	_apply()
	_save()

func _vol_db(slider: HSlider) -> float:
	var v := clampf(float(slider.value) / 100.0, 0.0, 1.0)
	if v <= 0.0:
		return -60.0
	return linear_to_db(v)

func _player() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("Player")

func _apply() -> void:
	var p := _player()
	if p != null:
		var mult := clampf(float(_sens.value) / 100.0, 0.2, 2.0)
		if p.get("mouse_sensitivity") != null:
			p.set("mouse_sensitivity", GameConfig.MOUSE_SENSITIVITY * mult)
		if p.get("base_fov") != null:
			p.set("base_fov", clampf(float(_fov.value), 60.0, 100.0))
		var fx := _camfx.button_pressed
		if p.get("head_bob_enabled") != null:
			p.set("head_bob_enabled", fx)
		if p.get("camera_shake_enabled") != null:
			p.set("camera_shake_enabled", fx)
		if p.get("weapon_bob_enabled") != null:
			p.set("weapon_bob_enabled", fx)
	var audio: Node = get_node_or_null("/root/GameAudio")
	if audio != null:
		if audio.has_method("set_master_volume_db"):
			audio.call("set_master_volume_db", _vol_db(_master))
		if audio.has_method("set_sfx_volume_db"):
			audio.call("set_sfx_volume_db", _vol_db(_sfx))
	var scene := get_tree().current_scene
	if scene != null:
		var sun := scene.get_node_or_null("DirectionalLight3D")
		if sun != null and sun.get("shadow_enabled") != null:
			sun.set("shadow_enabled", _shadows.button_pressed)

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "sensitivity", float(_sens.value))
	cfg.set_value("settings", "fov", float(_fov.value))
	cfg.set_value("settings", "master", float(_master.value))
	cfg.set_value("settings", "sfx", float(_sfx.value))
	cfg.set_value("settings", "shadows", _shadows.button_pressed)
	cfg.set_value("settings", "camera_fx", _camfx.button_pressed)
	cfg.save(SAVE_PATH)

func _load_and_apply() -> void:
	_loading = true
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		_sens.value = float(cfg.get_value("settings", "sensitivity", 100.0))
		_fov.value = float(cfg.get_value("settings", "fov", 75.0))
		_master.value = float(cfg.get_value("settings", "master", 100.0))
		_sfx.value = float(cfg.get_value("settings", "sfx", 100.0))
		_shadows.button_pressed = bool(cfg.get_value("settings", "shadows", true))
		_camfx.button_pressed = bool(cfg.get_value("settings", "camera_fx", true))
	_loading = false
	_apply()

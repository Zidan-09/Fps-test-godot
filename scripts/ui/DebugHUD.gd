extends CanvasLayer
## DebugHUD minimo - plan.md Secao 54/55 (F1 mostra/esconde).
## Fase 1 exibe: FPS, posicao, velocidade, estado da partida.

var _label: Label
var _visible_debug: bool = GameConfig.DEBUG_MODE

func _ready() -> void:
	_label = Label.new()
	_label.name = "DebugLabel"
	_label.position = Vector2(10, 10)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)
	_label.visible = _visible_debug

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		_visible_debug = not _visible_debug
		_label.visible = _visible_debug

func _process(_delta: float) -> void:
	if not _visible_debug or _label == null:
		return
	var player: Node = get_parent().get_node_or_null("Player")
	var gm: Node = get_parent().get_node_or_null("GameManager")
	var fps: int = int(Engine.get_frames_per_second())
	var pos_str := "n/a"
	var speed_str := "n/a"
	if player != null and player is CharacterBody3D:
		var p: Vector3 = (player as Node3D).global_position
		pos_str = "(%.1f, %.1f, %.1f)" % [p.x, p.y, p.z]
		var v: Vector3 = (player as CharacterBody3D).velocity
		speed_str = "%.1f m/s (y %.1f)" % [Vector2(v.x, v.z).length(), v.y]
	var state_str := "n/a"
	if gm != null and gm.get("current_state") != null:
		state_str = str(gm.get("current_state"))
	var move_str := "n/a"
	if player != null and player.has_method("get_move_state"):
		move_str = str(player.call("get_move_state"))
	_label.text = "DEBUG [F1]\nFPS: %d\nPos: %s\nVel: %s\nMove: %s\nState: %s\nWASD move | Shift corre | Ctrl/C desliza-agacha | Espaco pula | ESC libera mouse" % [fps, pos_str, speed_str, move_str, state_str]

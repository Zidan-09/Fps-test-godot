class_name FPSPlayer
extends CharacterBody3D
## FPS Player Controller - plan.md Secao 4.
## Fase 7: sprint + agachar + slide + efeitos de camera (tudo configuravel).
## REGRA DO PROJETO: armas sao instanciadas em codigo com guards; sem elas,
## o jogo abre em modo desarmado em vez de quebrar.

const PLAYER_NAME := "PLAYER"
const SWITCH_TIME := 0.25
const WEAPON_SCENE_PATH := "res://scenes/weapons/Weapon.tscn"
const DEFAULT_PRIMARY_PATH := "res://resources/weapons/AR01_Raptor.tres"
const DEFAULT_SECONDARY_PATH := "res://resources/weapons/PX9_Viper.tres"

## Posturas (Secao 7): em pe espelha o Player.tscn; agachado/slide abaixam tudo.
const STAND_SHAPE_HEIGHT := 1.8
const CROUCH_SHAPE_HEIGHT := 1.2
const STAND_HEAD_Y := 1.6
const CROUCH_HEAD_Y := 1.05

@export_group("Movimento")
@export var normal_speed: float = GameConfig.NORMAL_SPEED
@export var sprint_speed: float = GameConfig.SPRINT_SPEED
@export var acceleration: float = GameConfig.ACCELERATION
@export var air_control: float = GameConfig.AIR_CONTROL

@export_group("Agachar / Slide")
@export var crouch_speed: float = GameConfig.CROUCH_SPEED
@export var slide_min_speed: float = GameConfig.SLIDE_MIN_SPEED
@export var slide_boost: float = GameConfig.SLIDE_BOOST
@export var slide_friction: float = GameConfig.SLIDE_FRICTION
@export var slide_cooldown: float = GameConfig.SLIDE_COOLDOWN
@export var slide_enabled: bool = true

@export_group("Pulo / Gravidade")
@export var jump_velocity: float = GameConfig.JUMP_VELOCITY
@export var gravity: float = GameConfig.GRAVITY
@export var coyote_time: float = GameConfig.COYOTE_TIME

@export_group("Camera")
@export var mouse_sensitivity: float = GameConfig.MOUSE_SENSITIVITY
@export var base_fov: float = GameConfig.BASE_FOV
@export var sprint_fov: float = GameConfig.SPRINT_FOV
@export var fov_lerp_speed: float = GameConfig.FOV_LERP_SPEED
@export var pitch_min_deg: float = GameConfig.PITCH_MIN_DEG
@export var pitch_max_deg: float = GameConfig.PITCH_MAX_DEG

@export_group("Efeitos de camera")
@export var head_bob_enabled: bool = true
@export var camera_shake_enabled: bool = true
@export var weapon_bob_enabled: bool = true
@export var head_bob_amplitude: float = 0.035
@export var slide_tilt_deg: float = 8.0
@export var strafe_lean_deg: float = 1.5

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var health: Health = $Health
@onready var weapon_holder: Node3D = $Head/Camera3D/WeaponHolder
@onready var body_shape: CollisionShape3D = $CollisionShape3D

## Arma ativa (atalho) + inventario completo (Secao 24).
var weapon: Weapon
var weapons: Array[Weapon] = []
var active_index: int = 0

var _pitch: float = 0.0
var _coyote_timer: float = 0.0
var _is_sprinting: bool = false
var _ads: bool = false
var _dead: bool = false
var _respawn_left: float = 0.0
var _switch_left: float = 0.0
var _controls_locked: bool = true

var _crouched: bool = false
var _want_stand: bool = false
var _sliding: bool = false
var _slide_dir: Vector3 = Vector3.ZERO
var _slide_speed: float = 0.0
var _slide_time: float = 0.0
var _slide_cooldown_left: float = 0.0
var _fall_speed: float = 0.0
var _step_timer: float = 0.4
var _bob_phase: float = 0.0
var _trauma: float = 0.0
var _land_dip: float = 0.0
var _tilt_cur: float = 0.0
var _holder_dip: float = 0.0
var _cam_base_pos: Vector3 = Vector3(0.0, 0.1, 0.0)
var _holder_base_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	camera.fov = base_fov
	camera.current = true
	# Capsula duplicada: agachar altera a altura sem afetar a cena original.
	if body_shape != null and body_shape.shape != null:
		body_shape.shape = body_shape.shape.duplicate()
	if camera != null:
		_cam_base_pos = camera.position
	if weapon_holder != null:
		_holder_base_pos = weapon_holder.position
	_collect_weapons()
	if weapons.is_empty():
		set_loadout([DEFAULT_PRIMARY_PATH, DEFAULT_SECONDARY_PATH])
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	# Mouse/controles: liberados pela Main ou pelo LoadoutMenu. Comecam presos.

## Usa armas ja presentes no holder (composicao de cena) se existirem.
func _collect_weapons() -> void:
	weapons.clear()
	if weapon_holder == null:
		push_warning("[Player] sem WeaponHolder; modo desarmado.")
		return
	for child in weapon_holder.get_children():
		var w := child as Weapon
		if w == null:
			continue
		weapons.append(w)
		w.fired.connect(_apply_recoil)
	if weapons.is_empty():
		weapon = null
		return
	_normalize_inventory()

func _normalize_inventory() -> void:
	active_index = clampi(active_index, 0, weapons.size() - 1)
	for i in weapons.size():
		if i == active_index:
			weapons[i].draw()
		else:
			weapons[i].holster()
	weapon = weapons[active_index]

## Monta o loadout a partir de caminhos de WeaponData. Cada item ausente
## e ignorado com aviso; se nada carregar, segue desarmado (nunca crash).
func set_loadout(data_paths: Array) -> bool:
	if weapon_holder == null:
		push_warning("[Player] sem WeaponHolder; loadout ignorado.")
		return false
	if not ResourceLoader.exists(WEAPON_SCENE_PATH):
		push_warning("[Player] cena de arma ausente; modo desarmado.")
		return false
	var scene := load(WEAPON_SCENE_PATH) as PackedScene
	if scene == null:
		push_warning("[Player] falha ao carregar cena de arma.")
		return false
	for w in weapons:
		if is_instance_valid(w):
			weapon_holder.remove_child(w)
			w.queue_free()
	weapons.clear()
	weapon = null
	for path in data_paths:
		var p := str(path)
		if p.is_empty():
			continue
		if not ResourceLoader.exists(p):
			push_warning("[Player] arma ausente, ignorada: %s." % p)
			continue
		var data := load(p) as WeaponData
		if data == null:
			push_warning("[Player] dados de arma invalidos: %s." % p)
			continue
		var w := scene.instantiate() as Weapon
		if w == null:
			continue
		w.data = data
		w.name = "Weapon%d" % weapons.size()
		weapon_holder.add_child(w)
		w.fired.connect(_apply_recoil)
		weapons.append(w)
	if weapons.is_empty():
		push_warning("[Player] loadout vazio; modo desarmado.")
		EventBus.loadout_changed.emit()
		return false
	_normalize_inventory()
	_ads = false
	_switch_left = 0.0
	EventBus.loadout_changed.emit()
	EventBus.weapon_switched.emit(weapon.data.weapon_name)
	return true

func lock_controls() -> void:
	_controls_locked = true
	_ads = false
	_sliding = false
	_slide_cooldown_left = 0.0
	_want_stand = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func unlock_controls() -> void:
	_controls_locked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func get_active_weapon() -> Weapon:
	return weapon

func get_weapon_list() -> Array:
	return weapons.duplicate()

func is_dead() -> bool:
	return _dead

## Alvo valido para os bots (Secao 28): morto ou no menu, nao e percebido.
func is_targetable() -> bool:
	return not _dead and not _controls_locked

func is_ads() -> bool:
	return _ads

func _can_use_weapon() -> bool:
	return not _dead and not _controls_locked and weapon != null \
		and weapon.data != null and _switch_left <= 0.0

## Troca de arma (Secao 24). Falhas viram no-op com aviso, nunca crash.
func switch_to(idx: int) -> bool:
	if _dead or _controls_locked or weapons.size() < 2:
		return false
	if idx < 0 or idx >= weapons.size() or idx == active_index:
		return false
	if _switch_left > 0.0:
		return false
	weapon.cancel_reload()
	weapon.holster()
	active_index = idx
	weapon = weapons[active_index]
	weapon.draw()
	_ads = false
	_switch_left = SWITCH_TIME
	_sfx("play_swap")
	EventBus.weapon_switched.emit(weapon.data.weapon_name)
	return true

func switch_next() -> bool:
	if weapons.size() < 2:
		return false
	return switch_to((active_index + 1) % weapons.size())

func switch_prev() -> bool:
	if weapons.size() < 2:
		return false
	return switch_to((active_index - 1 + weapons.size()) % weapons.size())

func _sfx(method_name: String) -> void:
	var audio: Node = get_node_or_null("/root/GameAudio")
	if audio != null and audio.has_method(method_name):
		audio.call(method_name)

func _unhandled_input(event: InputEvent) -> void:
	# Pausa tem prioridade (PauseMenu consome no _input); aqui o ESC so
	# alterna o mouse fora da pausa para nao reabrir o cursor ao resumir.
	if event.is_action_pressed("pause") and not _controls_locked and not get_tree().paused:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _controls_locked:
		return
	# Mouse look: yaw no corpo, pitch na camera (Secao 9).
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not _dead:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		var sens: float = mouse_sensitivity * (0.7 if _ads else 1.0)
		rotate_y(-motion.relative.x * sens)
		_pitch = clampf(_pitch - motion.relative.y * sens,
				deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
		head.rotation.x = _pitch
	# Troca de armas (Secao 24). Guardas: sem travar se faltar arma.
	if not _dead and event.is_action_pressed("weapon_1"):
		switch_to(0)
	elif not _dead and event.is_action_pressed("weapon_2"):
		switch_to(1)
	elif not _dead and event.is_action_pressed("weapon_next"):
		switch_next()
	elif not _dead and event.is_action_pressed("weapon_prev"):
		switch_prev()
	# Agachar / slide (Secao 7): Ctrl com velocidade = slide, parado = agachar.
	if not _dead and event.is_action_pressed("crouch"):
		_on_crouch_pressed()
	elif event.is_action_released("crouch"):
		_on_crouch_released()
	if not _can_use_weapon():
		return
	# Semi-auto dispara um tiro por clique; automatico segura o botao.
	if event.is_action_pressed("fire") and weapon.data.fire_mode == WeaponData.FireMode.SEMI:
		weapon.try_fire(camera, self, PLAYER_NAME, _ads)
	if event.is_action_pressed("reload"):
		weapon.start_reload()

func _physics_process(delta: float) -> void:
	# --- Gravidade + coyote time (Secao 8) ---
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta
		velocity.y -= gravity * delta

	if _dead or _controls_locked:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	# --- Pulo (sem pulo infinito); pular cancela o slide ---
	if Input.is_action_just_pressed("jump") and _coyote_timer > 0.0:
		if _sliding:
			_sliding = false
			_slide_cooldown_left = slide_cooldown
		_want_stand = true
		velocity.y = jump_velocity
		_coyote_timer = 0.0
		_sfx("play_jump")

	# --- Direcao WASD relativa ao yaw do jogador ---
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish_dir: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y))
	wish_dir.y = 0.0
	if wish_dir.length() > 1.0:
		wish_dir = wish_dir.normalized()

	# --- Cooldown do slide corre sempre em jogo ---
	if _slide_cooldown_left > 0.0:
		_slide_cooldown_left -= delta

	# --- Tentativa de levantar (teto baixo mantem agachado, sem travar) ---
	if _want_stand and not _sliding:
		if _can_stand():
			_set_crouched(false)
			_want_stand = false
		elif not _crouched:
			_want_stand = false

	# --- Sprint: so para frente, em pe e sem deslizar ---
	var wants_sprint: bool = Input.is_action_pressed("sprint") and input_dir.y < 0.1 \
		and wish_dir.length() > 0.1 and not _crouched and not _sliding
	_is_sprinting = wants_sprint

	var was_on_floor: bool = is_on_floor()
	if not was_on_floor:
		_fall_speed = -velocity.y

	if _sliding:
		# --- Slide (Secao 7): direcao travada, atrito constante, leve controle ---
		_slide_time += delta
		_slide_speed = maxf(_slide_speed - slide_friction * delta, 0.0)
		if wish_dir.length() > 0.1:
			_slide_dir = (_slide_dir + wish_dir * 1.5 * delta).normalized()
		velocity.x = _slide_dir.x * _slide_speed
		velocity.z = _slide_dir.z * _slide_speed
		if _slide_speed < crouch_speed + 0.4 or _slide_time >= GameConfig.SLIDE_MAX_TIME \
				or not is_on_floor():
			_end_slide()
	else:
		# --- Velocidade: agachado < normal < sprint; ADS reduz (Secao 6) ---
		var target_speed: float = sprint_speed if _is_sprinting else normal_speed
		if _crouched:
			target_speed = crouch_speed
		if weapon != null and weapon.data != null:
			target_speed *= weapon.data.move_speed_multiplier
		if _ads:
			target_speed *= GameConfig.ADS_SPEED_MULTIPLIER

		# --- Aceleracao arcade: controle total no chao, parcial no ar ---
		var control: float = 1.0 if is_on_floor() else air_control
		var target_vel: Vector3 = wish_dir * target_speed
		velocity.x = lerpf(velocity.x, target_vel.x, clampf(acceleration * control * delta, 0.0, 1.0))
		velocity.z = lerpf(velocity.z, target_vel.z, clampf(acceleration * control * delta, 0.0, 1.0))

	move_and_slide()

	# --- Pouso: dip de camera + micro-shake proporcional a queda ---
	if not was_on_floor and is_on_floor():
		_on_landed(_fall_speed)
		_fall_speed = 0.0

	# --- Passos (Secao 52): intervalo cai com a velocidade ---
	var planar_now := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and planar_now > 2.0:
		_step_timer -= delta * planar_now
		if _step_timer <= 0.0:
			_step_timer = 2.4
			_sfx("play_step")
	else:
		_step_timer = 0.4

	# --- ADS: sem mirar em sprint maximo ou no slide (Secao 6) ---
	_ads = Input.is_action_pressed("aim") and not _is_sprinting and not _sliding

	# --- Tiro automatico com botao segurado ---
	if _can_use_weapon() and weapon.data.fire_mode == WeaponData.FireMode.AUTO \
			and Input.is_action_pressed("fire") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		weapon.try_fire(camera, self, PLAYER_NAME, _ads)

func _process(delta: float) -> void:
	if _switch_left > 0.0:
		_switch_left -= delta
	if _dead:
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			_respawn()
		return
	# FOV: ADS > sprint/slide > base (Secoes 6/20). Facilmente desativavel.
	var desired_fov: float = base_fov
	if _ads and weapon != null and weapon.data != null:
		desired_fov = weapon.data.ads_fov
	elif (_is_sprinting or _sliding) and velocity.length() > 4.0:
		desired_fov = sprint_fov
	camera.fov = lerpf(camera.fov, desired_fov, clampf(fov_lerp_speed * delta, 0.0, 1.0))
	_update_camera_effects(delta)

# ------------------------------------------------- agachar / slide (Secao 7)

func _on_crouch_pressed() -> void:
	if _dead or _controls_locked:
		return
	var planar := Vector2(velocity.x, velocity.z).length()
	if slide_enabled and _slide_cooldown_left <= 0.0 and is_on_floor() \
			and planar >= slide_min_speed and not _sliding:
		_start_slide(planar)
	else:
		_want_stand = false
		_set_crouched(true)

func _on_crouch_released() -> void:
	if _dead or _controls_locked:
		return
	if _sliding:
		return # o fim do slide decide: solto = levanta, segurado = agacha
	_want_stand = true

func _set_crouched(on: bool) -> void:
	if on == _crouched:
		return
	if on:
		_crouched = true
		_apply_stance(CROUCH_SHAPE_HEIGHT, CROUCH_HEAD_Y)
	else:
		if not _can_stand():
			_want_stand = true
			return
		_crouched = false
		_apply_stance(STAND_SHAPE_HEIGHT, STAND_HEAD_Y)

func _apply_stance(shape_h: float, head_y: float) -> void:
	if body_shape != null and body_shape.shape is CapsuleShape3D:
		var cap := body_shape.shape as CapsuleShape3D
		cap.height = shape_h
		body_shape.position.y = shape_h * 0.5
	if head != null:
		head.position.y = head_y

## Teto baixo? Continua agachado em vez de clipar a geometria.
func _can_stand() -> bool:
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3(0.0, CROUCH_SHAPE_HEIGHT + 0.1, 0.0)
	var to := global_position + Vector3(0.0, STAND_SHAPE_HEIGHT + 0.1, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude.append(get_rid())
	return space.intersect_ray(query).is_empty()

func _start_slide(planar_speed: float) -> void:
	_sliding = true
	_slide_time = 0.0
	_crouched = false
	_want_stand = false
	var dir := Vector3(velocity.x, 0.0, velocity.z)
	if dir.length() > 0.1:
		_slide_dir = dir.normalized()
	else:
		_slide_dir = -global_transform.basis.z
	_slide_dir.y = 0.0
	_slide_speed = planar_speed + slide_boost
	_ads = false
	_sfx("play_slide")
	_apply_stance(CROUCH_SHAPE_HEIGHT, CROUCH_HEAD_Y)

func _end_slide() -> void:
	if not _sliding:
		return
	_sliding = false
	_slide_cooldown_left = slide_cooldown
	if Input.is_action_pressed("crouch"):
		_set_crouched(true)
	elif not _crouched:
		_want_stand = true

func _on_landed(fall_speed: float) -> void:
	if fall_speed < 6.0:
		return
	_land_dip = clampf((fall_speed - 6.0) * 0.015, 0.02, 0.12)
	_sfx("play_land")
	if fall_speed > 10.0:
		add_trauma(0.15)

## Shake por trauma (Secao 9): dano e quedas duras. Zero = camera limpa.
func add_trauma(amount: float) -> void:
	if not camera_shake_enabled:
		return
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

## Bob + lean + tilt do slide + shake + dip de pouso + arma (Secao 9).
## Tudo visual: nunca altera fisica ou mira. Desligavel por export.
func _update_camera_effects(delta: float) -> void:
	if camera == null:
		return
	_trauma = maxf(_trauma - delta * 1.8, 0.0)
	var shake := _trauma * _trauma if camera_shake_enabled else 0.0
	var planar := Vector2(velocity.x, velocity.z).length()
	var moving := is_on_floor() and planar > 0.5 and not _dead and not _controls_locked
	if moving and (head_bob_enabled or weapon_bob_enabled) and not _ads:
		_bob_phase += delta * (4.0 + planar * 1.1)
	var bob_amp := head_bob_amplitude * clampf(planar / sprint_speed, 0.0, 1.0)
	if not head_bob_enabled or not moving:
		bob_amp = 0.0
	elif _ads:
		bob_amp *= 0.25
	var bob_y := sin(_bob_phase * 2.0) * bob_amp
	var bob_x := cos(_bob_phase) * bob_amp * 0.6
	_land_dip = lerpf(_land_dip, 0.0, clampf(8.0 * delta, 0.0, 1.0))
	var lean := 0.0
	if moving:
		lean = -Input.get_axis("move_left", "move_right") * deg_to_rad(strafe_lean_deg)
	var tilt_target := lean
	if _sliding:
		tilt_target += deg_to_rad(slide_tilt_deg)
	_tilt_cur = lerpf(_tilt_cur, tilt_target, clampf(8.0 * delta, 0.0, 1.0))
	var sh_y := sin(_bob_phase * 7.3) * 0.05 * shake
	var sh_x := cos(_bob_phase * 6.1) * 0.05 * shake
	var sh_roll := sin(_bob_phase * 5.7) * deg_to_rad(2.0) * shake
	camera.position = _cam_base_pos + Vector3(bob_x + sh_x, bob_y - _land_dip + sh_y, 0.0)
	camera.rotation.z = _tilt_cur + sh_roll
	# Arma acompanha: balanco suave + abaixa em sprint/slide (Secao 6).
	if weapon_holder != null and weapon_bob_enabled:
		var dip_target := 0.0
		if _sliding:
			dip_target = 0.16
		elif _is_sprinting and planar > 4.0:
			dip_target = 0.1
		_holder_dip = lerpf(_holder_dip, dip_target, clampf(8.0 * delta, 0.0, 1.0))
		weapon_holder.position = _holder_base_pos \
			+ Vector3(bob_x * 0.5, bob_y * 0.5 - _holder_dip, 0.0)

## Recoil funcional: camera sobe por tiro (Secao 21). Conectado ao sinal fired.
func _apply_recoil() -> void:
	if weapon == null or weapon.data == null:
		return
	_pitch = clampf(_pitch + deg_to_rad(weapon.data.recoil_pitch_deg),
			deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
	head.rotation.x = _pitch
	rotate_y(randf_range(-0.15, 0.15) * deg_to_rad(weapon.data.recoil_pitch_deg))

## Interface uniforme de dano (igual a dos dummies/bots). Retorna true se matou.
func take_damage(info: DamageInfo) -> bool:
	if _dead:
		return false
	health.take_damage(info)
	return not health.is_alive()

func _on_damaged(amount: float, _attacker_name: String) -> void:
	EventBus.damage_received.emit(PLAYER_NAME, amount, health.current)
	add_trauma(0.45)
	_sfx("play_hurt")

func _on_died(attacker_name: String) -> void:
	if _dead:
		return
	_dead = true
	_respawn_left = GameConfig.RESPAWN_DELAY
	_ads = false
	_switch_left = 0.0
	_sliding = false
	_slide_cooldown_left = 0.0
	_want_stand = false
	if weapon != null:
		weapon.cancel_reload()
	EventBus.player_died.emit(PLAYER_NAME, attacker_name)
	var gm: Node = get_parent().get_node_or_null("GameManager")
	if gm != null:
		if gm.has_method("register_combat_kill"):
			gm.call("register_combat_kill", attacker_name, PLAYER_NAME)
		elif gm.has_method("register_death"):
			gm.call("register_death")

func _respawn() -> void:
	_dead = false
	_pitch = 0.0
	head.rotation.x = 0.0
	velocity = Vector3.ZERO
	_crouched = false
	_want_stand = false
	_sliding = false
	_slide_cooldown_left = 0.0
	_trauma = 0.0
	_land_dip = 0.0
	_tilt_cur = 0.0
	_holder_dip = 0.0
	_apply_stance(STAND_SHAPE_HEIGHT, STAND_HEAD_Y)
	if camera != null:
		camera.position = _cam_base_pos
		camera.rotation.z = 0.0
	var spawn: Node = get_tree().get_first_node_in_group("player_spawn")
	if spawn is Node3D:
		global_position = (spawn as Node3D).global_position
		var target := Vector3(0, global_position.y, 0)
		if global_position.distance_to(target) > 0.1:
			look_at(target, Vector3.UP)
	else:
		push_warning("[Player] spawn 'player_spawn' nao encontrado; respawn no lugar.")
	health.refill()
	refill_all_weapons()
	if not weapons.is_empty() and active_index != 0:
		switch_to(0)
		_switch_left = 0.0
	EventBus.player_respawned.emit(PLAYER_NAME)

## API usada pelo debug e por fases futuras.
func get_speed_2d() -> float:
	return Vector2(velocity.x, velocity.z).length()

## Tempo restante de respawn (HUD da Fase 8).
func get_respawn_left() -> float:
	return maxf(_respawn_left, 0.0)

func is_sprinting() -> bool:
	return _is_sprinting

func is_crouched() -> bool:
	return _crouched

func is_sliding() -> bool:
	return _sliding

## Estado de movimento para debug/HUD (Fase 7/8).
func get_move_state() -> String:
	if _dead:
		return "MORTO"
	if _sliding:
		return "SLIDE"
	if not is_on_floor():
		return "AR"
	if _crouched:
		return "AGACHADO"
	if _is_sprinting:
		return "SPRINT"
	if Vector2(velocity.x, velocity.z).length() > 0.5:
		return "ANDA"
	return "PARADO"

func heal_full() -> void:
	health.refill()

## F2: recarrega todas as armas (Secao 55).
func refill_all_weapons() -> void:
	for w in weapons:
		if is_instance_valid(w):
			w.refill()

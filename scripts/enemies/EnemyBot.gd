class_name EnemyBot
extends CharacterBody3D
## EnemyBot - plan.md Secoes 26-29 (Fase 6: IA).
## CharacterBody3D + NavigationAgent3D com fallback de direcao direta
## (se o NavMesh nao assar, o bot anda em linha reta com wall-slide).
## Reusa Weapon (logica de tiro), Health e DummyHitbox (head/body).
## Estados: IDLE, PATROL, SEARCH, CHASE, ATTACK, TAKE_COVER, DEAD.
## Percepcao: distancia + angulo de visao + raycast de LOS
## (nao enxerga atraves de conteineres/paredes). Precisao imperfeita.

const WEAPON_SCENE_PATH := "res://scenes/weapons/Weapon.tscn"
const RAPTOR_PATH := "res://resources/weapons/AR01_Raptor.tres"
const CHEST := Vector3(0.0, 1.2, 0.0)
const GRAVITY := 18.0
const THINK_INTERVAL := 0.15

enum BotState { IDLE, PATROL, SEARCH, CHASE, ATTACK, TAKE_COVER, DEAD }

const PATROL_POINTS := [
	Vector3.ZERO,
	Vector3(12, 0, 0), Vector3(-12, 0, 0),
	Vector3(0, 0, 12), Vector3(0, 0, -12),
	Vector3(18, 0, 18), Vector3(-18, 0, -18),
	Vector3(18, 0, -18), Vector3(-18, 0, 18),
]

@export var bot_name := "BOT"
@export var difficulty := 1
@export var respawn_delay := 3.0
@export var attack_range := 20.0

@onready var health: Health = $Health
@onready var eye: Marker3D = $Eye
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var tag: Label3D = $NameTag

var state: int = BotState.IDLE
var weapon: Weapon
var nav_enabled := false
var target: Node3D
var last_known := Vector3.ZERO

var _vision_dist := 25.0
var _vision_ang := 90.0
var _reaction_time := 0.35
var _aim_err := 3.0
var _fire_int := 0.3
var _move_speed := 4.5
var _dmg_scale := 1.0

var _think := 0.0
var _reaction := 0.0
var _prev_target: Node3D
var _lost_sight := 0.0
var _burst_left := 0
var _burst_pause := 0.0
var _search_left := 0.0
var _cover_left := 0.0
var _cover_point := Vector3.ZERO
var _retreated := false
var _strafe_dir := 1.0
var _strafe_left := 0.0
var _dest := Vector3.ZERO
var _has_dest := false
var _stuck_time := 0.0
var _last_pos := Vector3.ZERO
var _dead := false
var _respawn_left := 0.0

func _ready() -> void:
	var cfg := BotDifficulty.get_preset(difficulty)
	_vision_dist = float(cfg.get("vision_distance", 25.0))
	_vision_ang = float(cfg.get("vision_angle", 90.0))
	_reaction_time = float(cfg.get("reaction", 0.35))
	_aim_err = float(cfg.get("aim_error", 3.0))
	_fire_int = float(cfg.get("fire_interval", 0.3))
	_move_speed = float(cfg.get("speed", 4.5))
	_dmg_scale = float(cfg.get("damage_scale", 1.0))
	if tag != null:
		tag.text = bot_name
	_build_weapon()
	if health != null:
		health.died.connect(_on_died)
	_last_pos = global_position
	if agent != null:
		agent.target_position = global_position
	state = BotState.PATROL

func _build_weapon() -> void:
	if not ResourceLoader.exists(WEAPON_SCENE_PATH) or not ResourceLoader.exists(RAPTOR_PATH):
		push_warning("[%s] Arma indisponivel; bot desarmado." % bot_name)
		return
	var scene := load(WEAPON_SCENE_PATH) as PackedScene
	var data := load(RAPTOR_PATH) as WeaponData
	if scene == null or data == null:
		return
	data = data.duplicate() as WeaponData
	data.damage *= _dmg_scale
	data.damage_min *= _dmg_scale
	weapon = scene.instantiate() as Weapon
	if weapon == null:
		return
	weapon.data = data
	weapon.name = "BotGun"
	weapon.visible = false # logica reutilizada; modelo FPS nao aparece no bot
	add_child(weapon)

## Alvo valido para outros bots (Secao 28: mortos nao sao percebidos).
func is_targetable() -> bool:
	return not _dead

## Interface uniforme de dano (hitboxes chamam take_hit; corpo chama take_damage).
func take_hit(info: DamageInfo, _is_head: bool) -> bool:
	if _dead or health == null:
		return false
	health.take_damage(info)
	if not health.is_alive():
		return true
	if not _retreated and health.ratio() < 0.4:
		_retreated = true
		_try_take_cover(info.attacker_name)
	elif state == BotState.PATROL or state == BotState.SEARCH:
		state = BotState.SEARCH # atingido: fica alerta procurando
		_search_left = 2.0
	return false

func take_damage(info: DamageInfo) -> bool:
	return take_hit(info, false)

func _node_for_attacker(attacker_name: String) -> Node3D:
	if attacker_name == FPSPlayer.PLAYER_NAME:
		var scene := get_tree().current_scene
		if scene != null:
			return scene.get_node_or_null("Player") as Node3D
		return null
	for n in get_tree().get_nodes_in_group("combatant"):
		if n != self and n.name == attacker_name and n is Node3D:
			return n as Node3D
	return null

func _try_take_cover(attacker_name: String) -> void:
	var attacker := _node_for_attacker(attacker_name)
	if attacker == null:
		state = BotState.SEARCH
		_search_left = 2.0
		return
	var away := global_position - attacker.global_position
	away.y = 0.0
	if away.length() < 0.5:
		away = Vector3(1, 0, 0)
	var p := global_position + away.normalized() * 6.0
	p.x = clampf(p.x, -23.0, 23.0)
	p.z = clampf(p.z, -23.0, 23.0)
	_cover_point = p
	_cover_left = 2.0
	_has_dest = false
	state = BotState.TAKE_COVER

func _physics_process(delta: float) -> void:
	if _dead:
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			_respawn()
		return
	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = -0.5
	else:
		velocity.y -= GRAVITY * delta
	_think -= delta
	if _think <= 0.0:
		_think = THINK_INTERVAL
		_think_update()
	_state_move(delta)
	move_and_slide()

# ---------------------------------------------------------------- percepcao

func _eye_pos() -> Vector3:
	if eye != null:
		return eye.global_position
	return global_position + Vector3(0, 1.6, 0)

func _has_los(t: Node3D) -> bool:
	var from := _eye_pos()
	var to: Vector3 = t.global_position + CHEST
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.exclude.append(get_rid())
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return false
	var c := hit["collider"] as Node
	return c == t or (c != null and c.get_parent() == t)

## Alvo: visivel mais proximo (player ou outro bot). Costas existem:
## fora do FOV so percebe a ate 4m (proximidade).
func _scan() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3(0, 0, -1)
	for n in get_tree().get_nodes_in_group("combatant"):
		if n == self or not (n is Node3D):
			continue
		if n.has_method("is_targetable") and not bool(n.call("is_targetable")):
			continue
		var t := n as Node3D
		var to: Vector3 = (t.global_position + CHEST) - _eye_pos()
		var dist := to.length()
		if dist > _vision_dist + 4.0:
			continue
		var flat := to
		flat.y = 0.0
		var ang := 0.0
		if flat.length() > 0.05:
			ang = rad_to_deg(acos(clampf(fwd.dot(flat.normalized()), -1.0, 1.0)))
		if not (ang <= _vision_ang * 0.5 or dist < 4.0):
			continue
		if not _has_los(t):
			continue
		if dist < best_d:
			best_d = dist
			best = t
	return best

func _think_update() -> void:
	if _reaction > 0.0:
		_reaction -= THINK_INTERVAL
	if _burst_pause > 0.0:
		_burst_pause -= THINK_INTERVAL
	var seen := _scan()
	if seen != null:
		if seen != _prev_target:
			_prev_target = seen
			_reaction = _reaction_time
		target = seen
		last_known = (seen as Node3D).global_position
		_lost_sight = 0.0
		var dist := global_position.distance_to(last_known)
		if state != BotState.TAKE_COVER:
			state = BotState.ATTACK if dist <= attack_range else BotState.CHASE
	else:
		if target != null:
			_lost_sight += THINK_INTERVAL
			if _lost_sight > 1.5 and (state == BotState.ATTACK or state == BotState.CHASE):
				state = BotState.SEARCH # ultimo local conhecido
				_search_left = 3.0
			elif state == BotState.ATTACK:
				state = BotState.CHASE
	if state == BotState.SEARCH:
		_search_left -= THINK_INTERVAL
		if _search_left <= 0.0:
			target = null
			_prev_target = null
			state = BotState.PATROL
			_has_dest = false
	if state == BotState.TAKE_COVER:
		_cover_left -= THINK_INTERVAL
		if _cover_left <= 0.0:
			state = BotState.ATTACK if target != null else BotState.PATROL

# ---------------------------------------------------------------- movimento

func _face_point(p: Vector3, delta: float, rate: float = 3.5) -> void:
	var d := p - global_position
	d.y = 0.0
	if d.length() < 0.05:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), clampf(rate * delta, 0.0, 1.0))

func _agent_usable(dest: Vector3) -> bool:
	if not nav_enabled or agent == null:
		return false
	agent.target_position = dest
	if agent.has_method("is_target_reachable") and not agent.is_target_reachable():
		return false
	return not agent.is_navigation_finished()

## Vai ate dest (NavMesh quando possivel, senao linha reta com wall-slide).
## Retorna true ao chegar (raio 1.2m).
func _steer_to(dest: Vector3, speed: float, _delta: float) -> bool:
	var flat := dest - global_position
	flat.y = 0.0
	if flat.length() < 1.2:
		velocity.x = 0.0
		velocity.z = 0.0
		return true
	var dir := flat.normalized()
	if _agent_usable(dest):
		var next := agent.get_next_path_position()
		var nd := next - global_position
		nd.y = 0.0
		if nd.length() > 0.2:
			dir = nd.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	_stuck_check()
	return false

## Destrava: sem progresso por 1.2s andando, tenta um desvio aleatorio.
func _stuck_check() -> void:
	if global_position.distance_to(_last_pos) > 0.3:
		_stuck_time = 0.0
		_last_pos = global_position
		return
	_stuck_time += get_physics_process_delta_time()
	if _stuck_time > 1.2:
		_stuck_time = 0.0
		_last_pos = global_position
		var a := randf() * TAU
		_dest = global_position + Vector3(cos(a), 0, sin(a)) * 4.0
		_dest.x = clampf(_dest.x, -23.0, 23.0)
		_dest.z = clampf(_dest.z, -23.0, 23.0)
		_has_dest = true

func _pick_patrol() -> void:
	var p: Vector3 = PATROL_POINTS[randi() % PATROL_POINTS.size()]
	_dest = p + Vector3(randf_range(-2.0, 2.0), 0, randf_range(-2.0, 2.0))
	_dest.x = clampf(_dest.x, -23.0, 23.0)
	_dest.z = clampf(_dest.z, -23.0, 23.0)
	_has_dest = true

func _state_move(delta: float) -> void:
	match state:
		BotState.PATROL:
			if not _has_dest:
				_pick_patrol()
			if _steer_to(_dest, _move_speed * 0.6, delta):
				_has_dest = false
			else:
				_face_point(global_position + Vector3(velocity.x, 0, velocity.z), delta)
		BotState.CHASE:
			_face_point(last_known, delta)
			_steer_to(last_known, _move_speed, delta)
		BotState.ATTACK:
			_attack_move(delta)
		BotState.SEARCH:
			velocity.x = 0.0
			velocity.z = 0.0
			rotate_y(1.2 * delta) # varredura do ultimo local conhecido
		BotState.TAKE_COVER:
			_steer_to(_cover_point, _move_speed, delta)
			_try_fire()
		_:
			velocity.x = 0.0
			velocity.z = 0.0

func _attack_move(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	_face_point(target.global_position, delta, 4.0)
	var to_t := target.global_position - global_position
	to_t.y = 0.0
	var dist := to_t.length()
	var dir := to_t.normalized() if dist > 0.05 else Vector3.ZERO
	_strafe_left -= delta
	if _strafe_left <= 0.0:
		_strafe_left = randf_range(0.8, 1.8)
		_strafe_dir = -_strafe_dir
		if randf() < 0.3:
			_strafe_dir = 0.0
	var side := Vector3(-dir.z, 0.0, dir.x) * _strafe_dir
	var radial := Vector3.ZERO
	if dist > 16.0:
		radial = dir
	elif dist < 7.0:
		radial = -dir
	var move := side * 0.7 + radial
	if move.length() > 0.05:
		move = move.normalized()
		velocity.x = move.x * _move_speed * 0.55
		velocity.z = move.z * _move_speed * 0.55
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	if eye != null:
		eye.look_at(_compute_aim())
	_try_fire()

## Mira com erro de precisao (dificuldade) + spread da arma. Nunca perfeita.
func _compute_aim() -> Vector3:
	var base: Vector3 = target.global_position + CHEST
	var from := _eye_pos()
	var dist := from.distance_to(base)
	var err_m := dist * tan(deg_to_rad(_aim_err))
	var right := global_transform.basis.x
	right.y = 0.0
	right = right.normalized() if right.length() > 0.01 else Vector3.RIGHT
	base += right * randf_range(-err_m, err_m)
	base.y += randf_range(-err_m, err_m) * 0.6
	return base

func _try_fire() -> void:
	if weapon == null or weapon.data == null:
		return
	if target == null or not is_instance_valid(target):
		return
	if eye == null:
		return
	if _reaction > 0.0 or _burst_pause > 0.0:
		return
	if weapon.mag <= 0 and weapon.reserve <= 0:
		weapon.refill() # bote "penteia" municao; nunca trava desarmado
		return
	if _burst_left <= 0:
		_burst_left = randi_range(3, 6)
	if weapon.try_fire(eye, self, bot_name, false):
		_burst_left -= 1
		if _burst_left <= 0:
			_burst_pause = _fire_int * randf_range(1.5, 2.5)

# ---------------------------------------------------------------- morte

func _on_died(attacker_name: String) -> void:
	if _dead:
		return
	_dead = true
	state = BotState.DEAD
	target = null
	_prev_target = null
	_respawn_left = respawn_delay
	velocity = Vector3.ZERO
	if weapon != null:
		weapon.cancel_reload()
	collision_layer = 0 # corpo nao bloqueia mais tiros
	var head_node := get_node_or_null("Head")
	if head_node != null:
		head_node.collision_layer = 0
	var tw := create_tween()
	tw.tween_property(self, "rotation:x", -PI * 0.5, 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	EventBus.enemy_died.emit(bot_name, attacker_name)
	var scene := get_tree().current_scene
	if scene != null:
		var gm := scene.get_node_or_null("GameManager")
		if gm != null and gm.has_method("register_combat_kill"):
			gm.call("register_combat_kill", attacker_name, bot_name)

func _respawn() -> void:
	_dead = false
	rotation = Vector3(0, randf() * TAU, 0)
	velocity = Vector3.ZERO
	global_position = _pick_spawn()
	collision_layer = 1
	var head_node := get_node_or_null("Head")
	if head_node != null:
		head_node.collision_layer = 1
	if health != null:
		health.refill()
	if weapon != null:
		weapon.refill()
	_retreated = false
	target = null
	_prev_target = null
	_has_dest = false
	_burst_left = 0
	_burst_pause = 0.0
	_reaction = 0.0
	_lost_sight = 0.0
	state = BotState.PATROL

## Spawn esperto e barato (Secao 30/31): 4 candidatos, fica o mais longe.
func _pick_spawn() -> Vector3:
	var marks := get_tree().get_nodes_in_group("spawn_points")
	var cands: Array = []
	for m in marks:
		if m is Node3D:
			cands.append(m)
	if cands.is_empty():
		return global_position
	var others := get_tree().get_nodes_in_group("combatant")
	var best: Node3D = cands[0]
	var best_d := -1.0
	for i in mini(4, cands.size()):
		var c: Node3D = cands[randi() % cands.size()]
		var md := 99999.0
		for o in others:
			if o == self or not (o is Node3D):
				continue
			md = minf(md, (o as Node3D).global_position.distance_to(c.global_position))
		if md > best_d:
			best_d = md
			best = c
	return best.global_position + Vector3(0, 0.2, 0)

class_name Weapon
extends Node3D
## Weapon - plan.md Secoes 13/14/19/21/22/23 (Fase 2: Combate).
## Hitscan generico via dados (WeaponData): cadencia, spread, falloff,
## headshot, reload, munição, muzzle flash, impacto e som procedural.
##
## Convencao de dano: qualquer corpo atingivel implementa
##   take_damage(info: DamageInfo) -> bool
## retornando true se o golpe matou o alvo (para hitmarker de kill).

signal ammo_changed(mag: int, reserve: int)
signal fired
signal reload_started
signal reload_finished
signal hit_confirmed(killed: bool, headshot: bool)
signal empty_clicked

@export var data: WeaponData

var mag: int = 0
var reserve: int = 0

var _cooldown: float = 0.0
var _reloading: bool = false
var _reload_left: float = 0.0
var _flash_timer: float = 0.0

@onready var muzzle: Marker3D = $Muzzle
@onready var flash: MeshInstance3D = $Flash

func _ready() -> void:
	refill()
	if is_instance_valid(flash):
		flash.visible = false
	ammo_changed.emit(mag, reserve)

## Audio centralizado e OPCIONAL (autoload GameAudio). Sem ele, a arma
## funciona em silencio: audio nunca quebra o gameplay (regra do projeto).
func _sfx(method_name: String) -> void:
	var audio: Node = get_node_or_null("/root/GameAudio")
	if audio != null and audio.has_method(method_name):
		audio.call(method_name)

## Restaura municao inicial (spawn / respawn / debug F2 futuro).
func refill() -> void:
	if data == null:
		return
	mag = data.magazine_size
	reserve = data.start_reserve
	_reloading = false
	_cooldown = 0.0
	ammo_changed.emit(mag, reserve)

func is_reloading() -> bool:
	return _reloading

func can_fire() -> bool:
	return data != null and not _reloading and _cooldown <= 0.0 and mag > 0

func start_reload() -> bool:
	if data == null or _reloading or mag >= data.magazine_size or reserve <= 0:
		return false
	_reloading = true
	_reload_left = data.reload_time
	_sfx("play_reload")
	reload_started.emit()
	return true

func cancel_reload() -> void:
	_reloading = false

## Guardar/sacar (Fase 3): cancela reload, zera cooldown e pausa o _process
## da arma inativa. A arma some da mao mas continua valida.
func holster() -> void:
	cancel_reload()
	_cooldown = 0.0
	visible = false
	set_process(false)

func draw() -> void:
	visible = true
	set_process(true)

func reload_progress() -> float:
	if data == null or not _reloading:
		return 0.0
	return clampf(1.0 - _reload_left / data.reload_time, 0.0, 1.0)

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and is_instance_valid(flash):
			flash.visible = false
	if _reloading:
		_reload_left -= delta
		if _reload_left <= 0.0:
			_finish_reload()

func _finish_reload() -> void:
	_reloading = false
	var need: int = data.magazine_size - mag
	var take: int = mini(need, reserve)
	mag += take
	reserve -= take
	reload_finished.emit()
	ammo_changed.emit(mag, reserve)

## Disparo principal. Chamado pelo Player (passa a Camera3D) e pelos bots
## (Fase 6, passam o Marker3D do olho): origem é qualquer Node3D.
func try_fire(shoot_origin: Node3D, attacker_body: Node3D, attacker_name: String, ads: bool) -> bool:
	if data == null or shoot_origin == null:
		return false
	if _reloading or _cooldown > 0.0:
		return false
	if mag <= 0:
		empty_clicked.emit()
		_sfx("play_empty")
		start_reload() # reload automatico ao puxar gatilho vazio
		return false
	mag -= 1
	_cooldown = data.shot_interval()
	var spread_deg: float = data.spread_ads_deg if ads else data.spread_hip_deg
	var pellets: int = maxi(data.pellets, 1)
	for i in pellets:
		_shoot_pellet(shoot_origin, attacker_body, attacker_name, ads, spread_deg)
	_show_flash()
	_play_shot()
	fired.emit()
	ammo_changed.emit(mag, reserve)
	return true

func _shoot_pellet(shoot_origin: Node3D, attacker_body: Node3D, attacker_name: String, ads: bool, spread_deg: float) -> void:
	var s: float = deg_to_rad(spread_deg)
	var local_dir := Vector3(randf_range(-s, s), randf_range(-s, s), -1.0).normalized()
	var dir: Vector3 = (shoot_origin.global_transform.basis * local_dir).normalized()
	var from: Vector3 = shoot_origin.global_position
	var to: Vector3 = from + dir * data.max_range
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if attacker_body != null and attacker_body.has_method("get_rid"):
		query.exclude.append(attacker_body.get_rid())
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var hit_pos: Vector3 = hit["position"]
	var collider: Object = hit["collider"]
	var distance: float = from.distance_to(hit_pos)
	var is_head: bool = (collider is Node) and (collider as Node).is_in_group("head")
	var is_flesh: bool = (collider is Node) and (collider as Node).is_in_group("shootable")
	var dmg: float = data.damage_at_distance(distance)
	if is_head:
		dmg *= data.headshot_multiplier
	if collider != null and collider.has_method("take_damage"):
		var info := DamageInfo.make(dmg, attacker_name, data.weapon_name, is_head, distance, hit_pos)
		var killed: bool = bool(collider.call("take_damage", info))
		hit_confirmed.emit(killed, is_head)
		_spawn_impact(hit_pos, Color(0.9, 0.15, 0.1) if is_flesh else Color(0.7, 0.65, 0.5))
	else:
		_spawn_impact(hit_pos, Color(0.7, 0.65, 0.5))

func _show_flash() -> void:
	if not is_instance_valid(flash):
		return
	flash.visible = true
	flash.rotation.z = randf() * TAU
	var fscale: float = randf_range(0.8, 1.3)
	flash.scale = Vector3(fscale, fscale, fscale)
	_flash_timer = 0.05

func _play_shot() -> void:
	_sfx("play_shot")

## Faisca/poeira leve no ponto de impacto (Secao 53, sem custo de assets).
## Otimizacao (Fase 10): malha e materiais compartilhados via cache estatico
## + rajada de particulas de um tiro so; sem alocacao de recurso por disparo.
static var _impact_mesh: SphereMesh
static var _impact_mats: Dictionary = {}

func _spawn_impact(pos: Vector3, color: Color) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	if _impact_mesh == null:
		_impact_mesh = SphereMesh.new()
		_impact_mesh.radius = 0.05
		_impact_mesh.height = 0.1
	var key := color.to_html()
	if not _impact_mats.has(key):
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		_impact_mats[key] = mat
	var dot := MeshInstance3D.new()
	dot.mesh = _impact_mesh
	dot.material_override = _impact_mats[key]
	scene.add_child(dot)
	dot.global_position = pos
	HitFX.burst(scene, pos, color)
	var tween: Tween = dot.create_tween()
	tween.set_parallel(true)
	tween.tween_property(dot, "scale", Vector3(0.05, 0.05, 0.05), 0.25)
	tween.chain().tween_callback(dot.queue_free)

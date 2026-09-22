class_name MapShipment
extends Node3D
## Mapa da Fase 5 (plan.md Secoes 32-37): arena 50x50 de conteineres.
## Original e procedural: inspirado apenas na ESTRUTURA do Shipment
## (cruz central perigosa + anel periferico quadrado). Nada de CoD aqui.
## Quatro clusters medios (N/S/L/O, com empilhados) + cantos + anel,
## cobertura baixa no centro, 2 plataformas com vista via degraus e 8 spawns.
## Geometria amigavel a navegacao (Fase 6): vaos livres >= 2.5m.

const HALF := 25.0
const CONTAINER := Vector3(6.0, 2.6, 2.4)
const DUMMY_SCENE: PackedScene = preload("res://scenes/enemies/TargetDummy.tscn")
const BOT_SCENE: PackedScene = preload("res://scenes/enemies/EnemyBot.tscn")

var _palette: Array = [
	Color(0.70, 0.16, 0.12), # vermelho ferrugem
	Color(0.12, 0.30, 0.65), # azul industrial
	Color(0.15, 0.50, 0.25), # verde
	Color(0.80, 0.65, 0.15), # amarelo
	Color(0.50, 0.51, 0.55), # cinza
]
var _codes: int = 0

func _ready() -> void:
	_build_floor_walls()
	_build_clusters()
	_build_center_cover()
	_build_mid_cover()
	_build_platforms()
	_build_lamps()
	_build_paint()
	_build_spawns()
	_build_dummies()
	call_deferred("_setup_nav_and_bots")

# ---------------------------------------------------------------- base

func _mat(color: Color, metallic: float = 0.0, rough: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = rough
	return m

func _emissive(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m

func _solid(box_name: String, size: Vector3, center: Vector3, color: Color,
		metallic: float = 0.0, rough: float = 0.85) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = center
	add_child(body)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color, metallic, rough)
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	col.shape = sh
	body.add_child(col)
	return body

func _visual(vname: String, mesh: Mesh, center: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = vname
	mi.position = center
	mi.mesh = mesh
	mi.material_override = mat
	add_child(mi)
	return mi

# ---------------------------------------------------------------- terreno

func _build_floor_walls() -> void:
	_solid("Floor", Vector3(HALF * 2.0, 0.2, HALF * 2.0), Vector3(0, -0.1, 0),
		Color(0.32, 0.33, 0.36), 0.15, 0.7)
	var h := 4.0
	_solid("WallN", Vector3(51.0, h, 1.0), Vector3(0, h * 0.5, -HALF - 0.5), Color(0.45, 0.46, 0.5))
	_solid("WallS", Vector3(51.0, h, 1.0), Vector3(0, h * 0.5, HALF + 0.5), Color(0.45, 0.46, 0.5))
	_solid("WallE", Vector3(1.0, h, 51.0), Vector3(HALF + 0.5, h * 0.5, 0), Color(0.45, 0.46, 0.5))
	_solid("WallW", Vector3(1.0, h, 51.0), Vector3(-HALF - 0.5, h * 0.5, 0), Color(0.45, 0.46, 0.5))

# ---------------------------------------------------------------- conteineres

func _pick_color(i: int) -> Color:
	return _palette[i % _palette.size()]

## base = ponto no chao (y=0). rot 0 = comprimento no eixo X.
func _container(base: Vector3, rot_y_deg: float, color_idx: int, stacked: bool = false) -> void:
	_codes += 1
	var code := "LK-%02d" % _codes
	_one_box(code, base, rot_y_deg, _pick_color(color_idx))
	if stacked:
		_one_box(code + "-UP", base + Vector3(0, CONTAINER.y, 0), rot_y_deg,
			_pick_color(color_idx).darkened(0.12))

func _one_box(code: String, base: Vector3, rot_y_deg: float, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Cont_" + code
	body.position = base
	body.rotation.y = deg_to_rad(rot_y_deg)
	add_child(body)
	# corpo metalico
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = CONTAINER
	mi.mesh = bm
	mi.position = Vector3(0, CONTAINER.y * 0.5, 0)
	mi.material_override = _mat(color, 0.35, 0.55)
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = CONTAINER
	col.shape = sh
	col.position = Vector3(0, CONTAINER.y * 0.5, 0)
	body.add_child(col)
	# faixa do teto (sombra/ferrugem)
	var roof := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(CONTAINER.x + 0.04, 0.08, CONTAINER.z + 0.04)
	roof.mesh = rm
	roof.position = Vector3(0, CONTAINER.y + 0.02, 0)
	roof.material_override = _mat(color.darkened(0.3), 0.4, 0.6)
	body.add_child(roof)
	# portas numa ponta (+X)
	var doors := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(0.06, 2.3, 2.1)
	doors.mesh = dm
	doors.position = Vector3(CONTAINER.x * 0.5 - 0.02, 1.3, 0)
	doors.material_override = _mat(Color(0.18, 0.18, 0.2), 0.5, 0.5)
	body.add_child(doors)
	# codigo pintado no costado (+Z)
	var tag := Label3D.new()
	tag.text = code
	tag.font_size = 96
	tag.pixel_size = 0.01
	tag.modulate = Color(0.92, 0.92, 0.9)
	tag.position = Vector3(0, 1.5, CONTAINER.z * 0.5 + 0.02)
	body.add_child(tag)
	return body

func _build_clusters() -> void:
	# Quatro medios ao redor do centro (empilhados = verticalidade contida).
	_container(Vector3(0, 0, -9), 0.0, 0, true) # N
	_container(Vector3(0, 0, 9), 0.0, 1, true) # S
	_container(Vector3(9, 0, 0), 90.0, 2, true) # L
	_container(Vector3(-9, 0, 0), 90.0, 3, true) # O
	# Quatro cantos (nivel do chao, fechando o anel).
	_container(Vector3(15, 0, -15), 0.0, 4)
	_container(Vector3(15, 0, 15), 0.0, 0)
	_container(Vector3(-15, 0, -15), 0.0, 1)
	_container(Vector3(-15, 0, 15), 0.0, 2)
	# Quatro do anel (quebram linhas de visao longas).
	_container(Vector3(-8, 0, -18), 0.0, 3)
	_container(Vector3(8, 0, -18), 0.0, 4)
	_container(Vector3(-8, 0, 18), 0.0, 2)
	_container(Vector3(8, 0, 18), 0.0, 0)

# ---------------------------------------------------------------- cobertura

func _crate(cname: String, size: float, center: Vector3) -> void:
	_solid(cname, Vector3(size, size, size), center, Color(0.55, 0.42, 0.28), 0.0, 0.9)

func _barrel(bname: String, base: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = bname
	body.position = base
	add_child(body)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.38
	cm.bottom_radius = 0.38
	cm.height = 0.95
	mi.mesh = cm
	mi.position = Vector3(0, 0.475, 0)
	mi.material_override = _mat(color, 0.4, 0.5)
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.height = 0.95
	sh.radius = 0.38
	col.shape = sh
	col.position = Vector3(0, 0.475, 0)
	body.add_child(col)

func _build_center_cover() -> void:
	# Centro propositalmente pobre em cobertura: perigoso, como no Shipment.
	_crate("CrateC1", 1.0, Vector3(0, 0.5, 3.5))
	_crate("CrateC2", 1.0, Vector3(0, 0.5, -3.5))
	_barrel("BarrelC1", Vector3(2.5, 0, 2.5), Color(0.6, 0.2, 0.12))
	_barrel("BarrelC2", Vector3(-2.5, 0, 2.5), Color(0.15, 0.35, 0.55))
	_barrel("BarrelC3", Vector3(2.5, 0, -2.5), Color(0.5, 0.5, 0.15))
	_barrel("BarrelC4", Vector3(-2.5, 0, -2.5), Color(0.3, 0.3, 0.32))

func _build_mid_cover() -> void:
	_crate("CrateM1", 1.2, Vector3(6, 0.6, 12))
	_crate("CrateM2", 1.2, Vector3(-6, 0.6, 12))
	_crate("CrateM3", 1.2, Vector3(6, 0.6, -12))
	_crate("CrateM4", 1.2, Vector3(-6, 0.6, -12))
	_barrel("BarrelM1", Vector3(12, 0, 2), Color(0.6, 0.2, 0.12))
	_barrel("BarrelM2", Vector3(12, 0, -2), Color(0.15, 0.35, 0.55))
	_barrel("BarrelM3", Vector3(-12, 0, 2), Color(0.15, 0.35, 0.55))
	_barrel("BarrelM4", Vector3(-12, 0, -2), Color(0.6, 0.2, 0.12))
	# pallets visuais (sem colisao para nao travar o pe).
	for i in 4:
		var px: float = 10.0 if i % 2 == 0 else -10.0
		var pz: float = 10.0 if i < 2 else -10.0
		var pm := BoxMesh.new()
		pm.size = Vector3(1.2, 0.12, 1.0)
		_visual("Pallet%d" % i, pm, Vector3(px, 0.06, pz), _mat(Color(0.5, 0.38, 0.25), 0.0, 0.95))

# ---------------------------------------------------------------- verticalidade

func _build_platforms() -> void:
	# Degrau 0.45 (pulavel: pulo alcanca ~0.69m) + plataforma 0.9 com vista do centro.
	_solid("PlatE", Vector3(2.5, 0.9, 2.5), Vector3(17, 0.45, 5), Color(0.4, 0.41, 0.45))
	_solid("StepE", Vector3(1.2, 0.45, 1.2), Vector3(17, 0.225, 7.2), Color(0.5, 0.38, 0.25), 0.0, 0.9)
	_solid("PlatW", Vector3(2.5, 0.9, 2.5), Vector3(-17, 0.45, -5), Color(0.4, 0.41, 0.45))
	_solid("StepW", Vector3(1.2, 0.45, 1.2), Vector3(-17, 0.225, -7.2), Color(0.5, 0.38, 0.25), 0.0, 0.9)

# ---------------------------------------------------------------- ambiente

func _lamp(base: Vector3, face_dir: Vector3) -> void:
	_solid("LampPole", Vector3(0.3, 5.0, 0.3), base + Vector3(0, 2.5, 0), Color(0.15, 0.15, 0.17), 0.5, 0.5)
	var hm := BoxMesh.new()
	hm.size = Vector3(0.9, 0.15, 0.4)
	var head := _visual("LampHead", hm, base + Vector3(0, 5.0, 0) + face_dir * 0.4,
		_emissive(Color(1.0, 0.8, 0.55), 2.0))
	head.rotation.y = atan2(-face_dir.x, -face_dir.z)

func _build_lamps() -> void:
	# Postes nos cantos, cabeca emissiva (sem luz real: performance).
	_lamp(Vector3(22, 0, 22), Vector3(-0.7, 0, -0.7).normalized())
	_lamp(Vector3(-22, 0, 22), Vector3(0.7, 0, -0.7).normalized())
	_lamp(Vector3(22, 0, -22), Vector3(-0.7, 0, 0.7).normalized())
	_lamp(Vector3(-22, 0, -22), Vector3(0.7, 0, 0.7).normalized())

func _build_paint() -> void:
	# Faixas pintadas no chao (visuais, sem colisao).
	var paint := _mat(Color(0.75, 0.65, 0.2), 0.0, 0.9)
	var s1 := BoxMesh.new()
	s1.size = Vector3(0.3, 0.02, 8.0)
	_visual("PaintN", s1, Vector3(0, 0.02, -5), paint)
	var s2 := BoxMesh.new()
	s2.size = Vector3(0.3, 0.02, 8.0)
	_visual("PaintS", s2, Vector3(0, 0.02, 5), paint)
	var s3 := BoxMesh.new()
	s3.size = Vector3(8.0, 0.02, 0.3)
	_visual("PaintE", s3, Vector3(5, 0.02, 0), paint)
	var s4 := BoxMesh.new()
	s4.size = Vector3(8.0, 0.02, 0.3)
	_visual("PaintW", s4, Vector3(-5, 0.02, 0), paint)

# ---------------------------------------------------------------- spawns e alvos

func _build_spawns() -> void:
	var pts := [
		Vector3(20, 0.2, 20), Vector3(-20, 0.2, 20),
		Vector3(20, 0.2, -20), Vector3(-20, 0.2, -20),
		Vector3(0, 0.2, 20), Vector3(0, 0.2, -20),
		Vector3(20, 0.2, 0), Vector3(-20, 0.2, 0),
	]
	for i in pts.size():
		var m := Marker3D.new()
		m.name = "Spawn%d" % i
		m.position = pts[i]
		m.add_to_group("spawn_points")
		add_child(m)
	var ps := Marker3D.new()
	ps.name = "PlayerSpawn"
	ps.position = Vector3(0, 0.2, 22)
	ps.add_to_group("player_spawn")
	ps.add_to_group("spawn_points")
	add_child(ps)

func _build_dummies() -> void:
	var defs := [
		["TARGET_A", Vector3(4, 0, -4)],
		["TARGET_B", Vector3(-4, 0, 4)],
		["TARGET_C", Vector3(5, 0, 5)],
		["TARGET_D", Vector3(-5, 0, -5)],
	]
	for d in defs:
		var dummy := DUMMY_SCENE.instantiate() as TargetDummy
		if dummy == null:
			push_warning("[Map] Falha ao instanciar dummy.")
			continue
		dummy.name = str(d[0])
		dummy.dummy_name = str(d[0])
		dummy.position = d[1] as Vector3
		add_child(dummy)

# ---------------------------------------------------------------- navegacao e bots (Fase 6)

## Assa o NavMesh em runtime (sem depender do editor) e spawna os bots.
## REGRA DO PROJETO: se o bake falhar, os bots usam direcao direta com
## wall-slide; o jogo nunca trava por causa da navegacao.
func _setup_nav_and_bots() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var nav_ok := _bake_navmesh()
	_spawn_bots(nav_ok)

func _bake_navmesh() -> bool:
	if not ClassDB.class_exists("NavigationMeshGenerator") \
			or not ClassDB.class_has_method("NavigationMeshGenerator", "bake", false):
		push_warning("[Map] Sem NavigationMeshGenerator; bots usam direcao direta.")
		return false
	var mesh := NavigationMesh.new()
	mesh.set("cell_size", 0.3)
	mesh.set("cell_height", 0.2)
	mesh.set("agent_radius", 0.35)
	mesh.set("agent_height", 1.7)
	mesh.set("agent_max_climb", 0.55)
	mesh.set("agent_max_slope", 45.0)
	mesh.set("geometry_parsed_geometry_type", 1) # so colisores estaticos
	# Origem da geometria: filhos do no raiz (o mapa). O padrao do engine
	# coleta por grupo ("navigation_mesh_source") e assaria 0 poligonos aqui.
	# Nome exato da propriedade tem prefixo geometry_ (ver docs NavigationMesh).
	mesh.set("geometry_source_geometry_mode", 0)
	mesh.set("geometry_collision_mask", 1) # mesma layer dos solidos do mapa
	var region := NavigationRegion3D.new()
	region.name = "NavRegion"
	region.navigation_mesh = mesh
	add_child(region)
	# bake() direto esta depreciado no 4.7 e assa vazio: pipeline em duas
	# etapas (parse na main thread + bake dos dados). Tudo via ClassDB com
	# guards; qualquer falha cai no fallback de direcao direta (regra).
	if not _bake_pipeline(mesh):
		push_warning("[Map] Pipeline de bake indisponivel; bots usam direcao direta.")
		region.queue_free()
		return false
	if mesh.get_polygon_count() == 0:
		push_warning("[Map] Bake gerou 0 poligonos; bots usam direcao direta.")
		region.queue_free()
		return false
	print("[BOOT] NavMesh assado: %d poligonos." % mesh.get_polygon_count())
	return true

func _bake_pipeline(mesh: NavigationMesh) -> bool:
	if not ClassDB.class_exists("NavigationMeshGenerator") \
			or not ClassDB.class_exists("NavigationMeshSourceGeometryData3D"):
		return false
	if not ClassDB.class_has_method("NavigationMeshGenerator", "parse_source_geometry_data", false) \
			or not ClassDB.class_has_method("NavigationMeshGenerator", "bake_from_source_geometry_data", false):
		return false
	var gen: Object = ClassDB.instantiate("NavigationMeshGenerator")
	var src: Object = ClassDB.instantiate("NavigationMeshSourceGeometryData3D")
	if gen == null or src == null:
		return false
	gen.call("parse_source_geometry_data", mesh, src, self)
	if src.get("vertices") is PackedVector3Array \
			and (src.get("vertices") as PackedVector3Array).is_empty():
		return false
	gen.call("bake_from_source_geometry_data", mesh, src)
	return true

func _spawn_bots(nav_ok: bool) -> void:
	var count := GameConfig.BOT_COUNT
	var diff := 1
	var gm := get_parent().get_node_or_null("GameManager")
	if gm != null:
		if gm.get("bot_count") != null:
			count = clampi(int(gm.get("bot_count")), 0, 7)
		if gm.get("bot_difficulty") != null:
			diff = clampi(int(gm.get("bot_difficulty")), 0, 2)
	var marks := get_tree().get_nodes_in_group("spawn_points")
	for i in count:
		var bot := BOT_SCENE.instantiate() as EnemyBot
		if bot == null:
			push_warning("[Map] Falha ao instanciar bot.")
			continue
		bot.name = "BOT_%02d" % (i + 1)
		bot.bot_name = bot.name
		bot.difficulty = diff
		bot.nav_enabled = nav_ok
		add_child(bot)
		if not marks.is_empty():
			var m := marks[randi() % marks.size()] as Node3D
			if m != null:
				bot.global_position = m.global_position
	print("[BOOT] %d bots spawnados (dificuldade %d, nav %s)." % [count, diff, " NavMesh" if nav_ok else "direta"])

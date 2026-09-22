class_name TestArena
extends Node3D
## Arena de teste da Fase 1 (plan.md Secao 62, item 12).
## Geometria procedural simples: chao, 4 paredes e obstaculos coloridos.
## Na Fase 5 sera substituida/ampliada pelo mapa de conteineres 50x50.

const FLOOR_SIZE := Vector3(30.0, 0.2, 30.0)
const WALL_HEIGHT := 3.0
const WALL_THICKNESS := 0.5
const DUMMY_SCENE: PackedScene = preload("res://scenes/enemies/TargetDummy.tscn")

func _ready() -> void:
	_add_box("Floor", FLOOR_SIZE, Vector3(0, -0.1, 0), Color(0.35, 0.35, 0.38))
	var half: float = 15.0
	_add_box("WallNorth", Vector3(30.0, WALL_HEIGHT, WALL_THICKNESS), Vector3(0, WALL_HEIGHT * 0.5, -half), Color(0.5, 0.5, 0.55))
	_add_box("WallSouth", Vector3(30.0, WALL_HEIGHT, WALL_THICKNESS), Vector3(0, WALL_HEIGHT * 0.5, half), Color(0.5, 0.5, 0.55))
	_add_box("WallEast", Vector3(WALL_THICKNESS, WALL_HEIGHT, 30.0), Vector3(half, WALL_HEIGHT * 0.5, 0), Color(0.5, 0.5, 0.55))
	_add_box("WallWest", Vector3(WALL_THICKNESS, WALL_HEIGHT, 30.0), Vector3(-half, WALL_HEIGHT * 0.5, 0), Color(0.5, 0.5, 0.55))
	# Coberturas simples para testar colisao e movimentacao.
	_add_box("Crate1", Vector3(1.5, 1.5, 1.5), Vector3(5, 0.75, 5), Color(0.75, 0.25, 0.2))
	_add_box("Crate2", Vector3(1.5, 1.5, 1.5), Vector3(-5, 0.75, 5), Color(0.2, 0.4, 0.75))
	_add_box("Crate3", Vector3(1.5, 1.5, 1.5), Vector3(5, 0.75, -5), Color(0.25, 0.6, 0.3))
	_add_box("Crate4", Vector3(1.5, 1.5, 1.5), Vector3(-5, 0.75, -5), Color(0.8, 0.7, 0.2))
	_add_box("Platform", Vector3(4.0, 1.0, 4.0), Vector3(0, 0.5, 0), Color(0.45, 0.45, 0.48))
	# Spawns da Fase 1 (Fase 6/31 expande para SpawnPoint3D com avaliacao).
	_add_spawn("PlayerSpawn", Vector3(0, 0.2, 10), true)
	_add_spawn("SpawnA", Vector3(-10, 0.2, -10))
	_add_spawn("SpawnB", Vector3(10, 0.2, -10))
	_add_spawn("SpawnC", Vector3(0, 0.2, -12))
	# Alvos de treino da Fase 2 (tiro/dano/headshot sem IA).
	_add_dummy("TARGET_A", Vector3(-4, 0, -4))
	_add_dummy("TARGET_B", Vector3(4, 0, -4))
	_add_dummy("TARGET_C", Vector3(0, 0, -8))

func _add_box(box_name: String, size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = pos
	add_child(body)
	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body

func _add_spawn(spawn_name: String, pos: Vector3, is_player_spawn: bool = false) -> Marker3D:
	var marker := Marker3D.new()
	marker.name = spawn_name
	marker.position = pos
	if is_player_spawn:
		marker.add_to_group("player_spawn")
	add_child(marker)
	return marker

func _add_dummy(dummy_name: String, pos: Vector3) -> TargetDummy:
	var dummy := DUMMY_SCENE.instantiate() as TargetDummy
	dummy.name = dummy_name
	dummy.dummy_name = dummy_name
	dummy.position = pos
	add_child(dummy)
	return dummy

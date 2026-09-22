class_name HitFX
extends RefCounted
## HitFX - rajadas de particulas procedurais de um tiro so (Secao 53, Fase 10).
## Sem texturas ou assets: pontos billboard coloridos via ParticleProcessMaterial.
## Malha compartilhada + um material por cor em cache estatico (otimizacao:
## zero alocacao de recurso por impacto). Uso: HitFX.burst(cena, pos, cor).

static var _quad: QuadMesh
static var _mats: Dictionary = {}

static func burst(parent: Node, pos: Vector3, color: Color, amount: int = 8) -> void:
	if parent == null:
		return
	if _quad == null:
		_quad = QuadMesh.new()
		_quad.size = Vector2(0.07, 0.07)
	var key := color.to_html()
	if not _mats.has(key):
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.albedo_color = color
		_mats[key] = mat
	var p := GPUParticles3D.new()
	p.amount = clampi(amount, 2, 16)
	p.lifetime = 0.35
	p.one_shot = true
	p.explosiveness = 0.9
	p.visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 60.0
	pm.initial_velocity_min = 1.5
	pm.initial_velocity_max = 4.0
	pm.gravity = Vector3(0, -9, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	pm.color = color
	p.process_material = pm
	p.draw_pass_1 = _quad
	if p is GeometryInstance3D:
		(p as GeometryInstance3D).material_override = _mats[key]
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)

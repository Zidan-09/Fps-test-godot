class_name DummyHitbox
extends StaticBody3D
## Hitbox reutilizavel: corpo ou cabeca.
## Fase 2 usa nos TargetDummy; Fase 6 reusa nos bots.
## O Weapon detecta headshot pelo grupo "head" e chama take_damage().

@export var is_head: bool = false

func take_damage(info: DamageInfo) -> bool:
	var owner_node: Node = get_parent()
	if owner_node != null and owner_node.has_method("take_hit"):
		return bool(owner_node.call("take_hit", info, is_head))
	return false

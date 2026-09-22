class_name DamageInfo
extends RefCounted
## DamageInfo - plan.md Secao 11.
## Pacote generico de dano: arma, atacante, headshot, distancia, etc.
## Usado por Health.take_damage() em player, dummies e (Fase 6) bots.

var amount: float = 0.0
var attacker_name: String = ""
var weapon_name: String = ""
var is_headshot: bool = false
var distance: float = 0.0
var hit_position: Vector3 = Vector3.ZERO

static func make(p_amount: float, p_attacker: String, p_weapon: String,
		p_headshot: bool = false, p_distance: float = 0.0,
		p_hit_position: Vector3 = Vector3.ZERO) -> DamageInfo:
	var info := DamageInfo.new()
	info.amount = p_amount
	info.attacker_name = p_attacker
	info.weapon_name = p_weapon
	info.is_headshot = p_headshot
	info.distance = p_distance
	info.hit_position = p_hit_position
	return info

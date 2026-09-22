class_name WeaponData
extends Resource
## WeaponData - plan.md Secao 13.
## Resource da Godot: novas armas sao criadas pelo editor (.tres)
## sem modificar codigo. Fase 2 usa 1 arma (Raptor); Fase 4 adiciona as demais.

enum FireMode { AUTO, SEMI }
enum FireType { HITSCAN, PELLETS }

@export_group("Identidade")
@export var weapon_name: String = "AR-01 \"Raptor\""
@export var category: String = "Assault Rifle"

@export_group("Dano")
@export var damage: float = 22.0
@export var damage_min: float = 14.0
@export var headshot_multiplier: float = 2.0
@export var max_range: float = 100.0
@export var effective_range: float = 40.0

@export_group("Cadencia e municao")
@export var fire_rate: float = 600.0 ## tiros por minuto
@export var magazine_size: int = 30
@export var start_reserve: int = 90
@export var reload_time: float = 2.2
@export var fire_mode: FireMode = FireMode.AUTO
@export var fire_type: FireType = FireType.HITSCAN
@export var pellets: int = 1 ## >1 para shotgun (Fase 4)

@export_group("Manuseio")
@export var spread_hip_deg: float = 1.5
@export var spread_ads_deg: float = 0.4
@export var recoil_pitch_deg: float = 0.35
@export var move_speed_multiplier: float = 1.0
@export var ads_fov: float = 55.0

## Intervalo entre disparos em segundos.
func shot_interval() -> float:
	return 60.0 / maxf(fire_rate, 1.0)

## Dano com falloff por distancia: cheio ate effective_range,
## cai linearmente ate damage_min em max_range.
func damage_at_distance(distance: float) -> float:
	if distance <= effective_range:
		return damage
	var t: float = clampf((distance - effective_range) / maxf(max_range - effective_range, 0.01), 0.0, 1.0)
	return lerpf(damage, damage_min, t)

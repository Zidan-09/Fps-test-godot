class_name Health
extends Node
## Health - plan.md Secao 10. Componente reutilizavel (player, dummies, bots).
## HP max 100, morte e regeneracao automatica apos REGEN_DELAY sem dano.

signal health_changed(current: float, maximum: float)
signal damaged(amount: float, attacker_name: String)
signal died(attacker_name: String)

@export var max_health: float = GameConfig.MAX_HEALTH
@export var regen_enabled: bool = true
@export var regen_delay: float = GameConfig.REGEN_DELAY
@export var regen_rate: float = GameConfig.REGEN_RATE

var current: float = 0.0
var _regen_timer: float = 0.0

func _ready() -> void:
	current = max_health

func _process(delta: float) -> void:
	if not regen_enabled or not is_alive():
		return
	if _regen_timer > 0.0:
		_regen_timer -= delta
		return
	if current < max_health:
		current = minf(current + regen_rate * delta, max_health)
		health_changed.emit(current, max_health)

func is_alive() -> bool:
	return current > 0.0

func take_damage(info: DamageInfo) -> void:
	if not is_alive():
		return
	current = maxf(current - info.amount, 0.0)
	_regen_timer = regen_delay
	damaged.emit(info.amount, info.attacker_name)
	health_changed.emit(current, max_health)
	if current <= 0.0:
		died.emit(info.attacker_name)

func heal(amount: float) -> void:
	if not is_alive():
		return
	current = minf(current + amount, max_health)
	health_changed.emit(current, max_health)

func refill() -> void:
	current = max_health
	_regen_timer = 0.0
	health_changed.emit(current, max_health)

func ratio() -> float:
	return clampf(current / maxf(max_health, 1.0), 0.0, 1.0)

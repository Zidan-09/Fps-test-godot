class_name TargetDummy
extends Node3D
## TargetDummy - alvo de treino da Fase 2 (equivale a "morte" sem IA).
## Recebe dano via DummyHitbox, cai ao morrer e levanta apos respawn_delay.
## NOTA: mortes de dummy NAO contam no placar (placar chega na Fase 9).

@export var dummy_name: String = "TARGET"
@export var respawn_delay: float = 3.0

@onready var health: Health = $Health

var _dead: bool = false
var _respawn_left: float = 0.0
var _upright_rotation: Vector3

func _ready() -> void:
	_upright_rotation = rotation
	health.died.connect(_on_died)

func _process(delta: float) -> void:
	if not _dead:
		return
	_respawn_left -= delta
	if _respawn_left <= 0.0:
		_respawn()

## Chamado pela DummyHitbox. O Weapon ja aplicou falloff e headshot;
## aqui o valor entra direto no Health. Retorna true se matou.
func take_hit(info: DamageInfo, _is_head: bool) -> bool:
	if _dead:
		return false
	health.take_damage(info)
	return not health.is_alive()

func _on_died(attacker_name: String) -> void:
	_dead = true
	_respawn_left = respawn_delay
	# Cai de costas (tween simples, sem AnimationPlayer nesta fase).
	var tween: Tween = create_tween()
	tween.tween_property(self, "rotation:x", _upright_rotation.x - PI * 0.5, 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	EventBus.enemy_died.emit(dummy_name, attacker_name)

func _respawn() -> void:
	_dead = false
	health.refill()
	rotation = _upright_rotation

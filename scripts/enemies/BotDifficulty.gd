class_name BotDifficulty
extends RefCounted
## Dificuldades dos bots - plan.md Secao 29.
## EASY/NORMAL/HARD modificam reacao, precisao, deteccao e agressividade.
## Bots nunca tem precisao perfeita.

const PRESETS := {
	0: {
		"label": "EASY", "vision_distance": 20.0, "vision_angle": 70.0,
		"reaction": 0.6, "aim_error": 5.0, "fire_interval": 0.5,
		"speed": 3.5, "damage_scale": 0.7,
	},
	1: {
		"label": "NORMAL", "vision_distance": 25.0, "vision_angle": 90.0,
		"reaction": 0.35, "aim_error": 3.0, "fire_interval": 0.3,
		"speed": 4.5, "damage_scale": 1.0,
	},
	2: {
		"label": "HARD", "vision_distance": 32.0, "vision_angle": 110.0,
		"reaction": 0.2, "aim_error": 1.5, "fire_interval": 0.18,
		"speed": 5.2, "damage_scale": 1.2,
	},
}

static func get_preset(d: int) -> Dictionary:
	return (PRESETS.get(clampi(d, 0, 2)) as Dictionary).duplicate()

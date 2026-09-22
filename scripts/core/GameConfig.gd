class_name GameConfig
extends RefCounted
## Configuracao centralizada do projeto (plan.md Secao 51).
## Evita valores magicos espalhados pelos scripts.
## Fase 1 usa: movimento, gravidade, pulo, camera. Demais valores
## ja ficam reservados para as proximas fases.

# --- Movimento (Secao 6) ---
const NORMAL_SPEED: float = 5.5
const SPRINT_SPEED: float = 8.5
const CROUCH_SPEED: float = 2.8
const ADS_SPEED_MULTIPLIER: float = 0.6
const ACCELERATION: float = 14.0
const AIR_CONTROL: float = 0.35

# --- Pulo / Gravidade (Secao 8) ---
const JUMP_VELOCITY: float = 5.0
const GRAVITY: float = 18.0
const COYOTE_TIME: float = 0.12

# --- Slide (Secao 7, implementacao completa na Fase 7) ---
const SLIDE_MIN_SPEED: float = 6.0
const SLIDE_BOOST: float = 3.0
const SLIDE_FRICTION: float = 4.0
const SLIDE_COOLDOWN: float = 1.2
const SLIDE_MAX_TIME: float = 1.0

# --- Camera FPS (Secao 9) ---
const MOUSE_SENSITIVITY: float = 0.0025
const PITCH_MIN_DEG: float = -89.0
const PITCH_MAX_DEG: float = 89.0
const BASE_FOV: float = 75.0
const SPRINT_FOV: float = 82.0
const ADS_FOV: float = 55.0
const FOV_LERP_SPEED: float = 10.0

# --- Vida (Secao 10) ---
const MAX_HEALTH: float = 100.0
const REGEN_DELAY: float = 3.0
const REGEN_RATE: float = 25.0

# --- Dano (Secao 11/19) ---
const BODY_MULTIPLIER: float = 1.0
const HEAD_MULTIPLIER: float = 2.0

# --- Partida (Secao 2/46) ---
const MATCH_DURATION_SEC: float = 300.0
const BOT_COUNT: int = 7
const MAX_PLAYERS: int = 8
const KILL_LIMIT: int = 30
const RESPAWN_DELAY: float = 2.0

# --- Debug (Secao 54/55) ---
const DEBUG_MODE: bool = true

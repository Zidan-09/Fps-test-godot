extends Node
## GameAudio (autoload) - plan.md Secao 52.
## REGRA DO PROJETO: audio nunca impede o jogo de abrir.
## - Nenhum arquivo de audio e necessario: todos os SFX sao procedurais.
## - ZERO referencias estaticas a classes de audio: tudo via ClassDB + set/call,
##   com suporte aos nomes "AudioStreamWav" e "AudioStreamWAV" (o nome mudou
##   entre versoes do engine). Se nada existir, vira no-op silencioso.
## - Ninguem referencia "GameAudio" direto: usem get_node_or_null("/root/GameAudio")
##   + has_method, para o jogo funcionar mesmo sem este autoload.

const POOL_SIZE := 8
const WAV_CLASS_NAMES: Array = ["AudioStreamWav", "AudioStreamWAV"]
const FORMAT_8_BITS_VALUE := 0 ## AudioStreamWav.FORMAT_8_BITS nas versoes conhecidas

var _ok: bool = false
var _wav_class: String = ""
var _streams: Dictionary = {}
var _pool: Array = []
var _pool_idx: int = 0
var _sfx_bus: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_wav_class = _detect_wav_class()
	if _wav_class.is_empty() or not ClassDB.class_exists("AudioStreamPlayer"):
		push_warning("[BOOT] Audio indisponivel nesta versao do engine; jogo segue sem som.")
		return
	_ensure_sfx_bus()
	for i in POOL_SIZE:
		var p: Object = ClassDB.instantiate("AudioStreamPlayer")
		if p == null:
			continue
		p.set("bus", &"SFX" if _sfx_bus >= 0 else &"Master")
		add_child(p as Node)
		_pool.append(p)
	if _pool.is_empty():
		push_warning("[BOOT] Nao foi possivel criar players de audio; jogo segue sem som.")
		return
	_ok = _build_all()
	if _ok:
		print("[BOOT] Audio procedural OK (12 SFX).")
	else:
		push_warning("[BOOT] Audio procedural indisponivel; jogo segue sem som.")

## Excecao consciente a regra "sem refs estaticas": AudioServer e singleton
## estavel do engine; o guard ClassDB mantem o no-op se ele nao existir.
func _ensure_sfx_bus() -> void:
	if _sfx_bus >= 0 or not ClassDB.class_exists("AudioServer"):
		return
	AudioServer.add_bus(-1)
	_sfx_bus = AudioServer.bus_count - 1
	AudioServer.set_bus_name(_sfx_bus, "SFX")

func available() -> bool:
	return _ok

## Volumes (Settings, Secao 43): 0.0 = cheio, <= -60 = mudo.
func set_master_volume_db(db: float) -> void:
	if ClassDB.class_exists("AudioServer"):
		AudioServer.set_bus_volume_db(0, clampf(db, -60.0, 0.0))

func set_sfx_volume_db(db: float) -> void:
	if not ClassDB.class_exists("AudioServer"):
		return
	_ensure_sfx_bus()
	if _sfx_bus >= 0:
		AudioServer.set_bus_volume_db(_sfx_bus, clampf(db, -60.0, 0.0))

func play_shot() -> void:
	_play("shot", 1.0, -8.0)

func play_empty() -> void:
	_play("click", 1.2, -10.0)

func play_reload() -> void:
	_play("reload", 0.9, -10.0)

func play_swap() -> void:
	_play("swap", 1.1, -12.0)

func play_hit() -> void:
	_play("hit", 1.0, -10.0)

func play_headshot() -> void:
	_play("headshot", 1.0, -8.0)

func play_kill() -> void:
	_play("kill", 1.0, -8.0)

func play_hurt() -> void:
	_play("hurt", 1.0, -8.0)

func play_death() -> void:
	_play("death", 1.0, -8.0)

func play_step() -> void:
	_play("step", randf_range(0.9, 1.1), -16.0)

func play_jump() -> void:
	_play("jump", 1.0, -14.0)

func play_land() -> void:
	_play("land", 1.0, -12.0)

func play_slide() -> void:
	_play("slide", 1.0, -12.0)

func play_ui() -> void:
	_play("ui", 1.0, -12.0)

func _detect_wav_class() -> String:
	for c in WAV_CLASS_NAMES:
		if ClassDB.class_exists(String(c)):
			return String(c)
	push_warning("[Audio] Nenhuma classe WAV encontrada (tentado: %s)." % ", ".join(WAV_CLASS_NAMES))
	return ""

func _play(key: String, pitch: float, vol_db: float) -> void:
	if not _ok or not _streams.has(key) or _pool.is_empty():
		return
	var p: Object = _pool[_pool_idx] as Object
	_pool_idx = (_pool_idx + 1) % POOL_SIZE
	if p == null or not is_instance_valid(p):
		return
	p.set("stream", _streams[key])
	p.set("pitch_scale", pitch * randf_range(0.96, 1.04))
	p.set("volume_db", vol_db)
	p.call("play")

func _build_all() -> bool:
	# nome: [duracao_s, ganho_ruido, freq_tom, decaimento]
	var specs := {
		"shot": [0.15, 0.7, 40.0, 18.0],
		"click": [0.05, 0.4, 1200.0, 60.0],
		"reload": [0.12, 0.5, 600.0, 25.0],
		"swap": [0.08, 0.45, 900.0, 35.0],
		"hit": [0.07, 0.5, 1800.0, 50.0],
		"headshot": [0.09, 0.5, 2400.0, 45.0],
		"kill": [0.18, 0.4, 300.0, 12.0],
		"hurt": [0.2, 0.6, 150.0, 10.0],
		"death": [0.4, 0.5, 90.0, 6.0],
		"step": [0.06, 0.35, 300.0, 40.0],
		"jump": [0.1, 0.3, 500.0, 20.0],
		"land": [0.12, 0.5, 120.0, 18.0],
		"slide": [0.25, 0.4, 200.0, 8.0],
		"ui": [0.06, 0.3, 800.0, 40.0],
	}
	for key: String in specs.keys():
		var s: Array = specs[key]
		var wav: Object = _make_burst(float(s[0]), float(s[1]), float(s[2]), float(s[3]))
		if wav == null:
			push_warning("[Audio] falha ao gerar SFX '%s'." % key)
			return false
		var data: Variant = wav.get("data")
		if not (data is PackedByteArray) or (data as PackedByteArray).is_empty():
			push_warning("[Audio] SFX '%s' com dados invalidos." % key)
			return false
		if int(wav.get("mix_rate")) <= 0:
			push_warning("[Audio] SFX '%s' com mix_rate invalido." % key)
			return false
		_streams[key] = wav
	return true

func _make_burst(duration: float, noise_gain: float, tone_freq: float, decay: float) -> Object:
	var rate: int = 22050
	var count: int = int(rate * duration)
	if count <= 0 or _wav_class.is_empty():
		return null
	var bytes := PackedByteArray()
	bytes.resize(count)
	for i in count:
		var t: float = float(i) / float(count)
		var env: float = exp(-t * decay)
		var tone: float = sin(t * tone_freq) * exp(-t * 30.0) * 0.6
		var sample: float = clampf((randf_range(-1.0, 1.0) * noise_gain + tone) * env, -1.0, 1.0)
		bytes[i] = int((sample * 0.5 + 0.5) * 255.0)
	var wav: Object = ClassDB.instantiate(_wav_class)
	if wav == null:
		return null
	wav.set("format", FORMAT_8_BITS_VALUE)
	wav.set("mix_rate", rate)
	wav.set("stereo", false)
	wav.set("data", bytes)
	return wav

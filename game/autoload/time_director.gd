extends Node

signal flash_requested(color: Color, duration_ms: int, max_alpha: float)

var camera_offset: Vector2 = Vector2.ZERO

var _slowmo_until_ms: int = 0
var _slowmo_scale: float = 1.0
var _default_scale: float = 1.0

var _shake_until_ms: int = 0
var _shake_total_ms: int = 0
var _shake_strength: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()


func request_hit_stop(duration_ms: int, slowmo_scale: float = 0.08) -> void:
	_default_scale = 1.0
	_slowmo_scale = max(slowmo_scale, 0.01)
	_slowmo_until_ms = Time.get_ticks_msec() + duration_ms
	Engine.time_scale = _slowmo_scale


func request_shake(duration_ms: int, strength: float = 12.0) -> void:
	_shake_until_ms = Time.get_ticks_msec() + duration_ms
	_shake_total_ms = duration_ms
	_shake_strength = max(strength, 0.0)


func request_flash(color: Color, duration_ms: int = 120, max_alpha: float = 0.9) -> void:
	flash_requested.emit(color, duration_ms, max_alpha)


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if _slowmo_until_ms > 0 and now >= _slowmo_until_ms:
		_slowmo_until_ms = 0
		Engine.time_scale = _default_scale

	if _shake_until_ms > now:
		var remain: float = float(_shake_until_ms - now) / max(float(_shake_total_ms), 1.0)
		camera_offset = Vector2(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0)
		) * _shake_strength * remain
	else:
		camera_offset = camera_offset.lerp(Vector2.ZERO, 0.35)

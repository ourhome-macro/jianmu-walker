extends Node2D

signal finished

var target: Node2D = null
var mode: StringName = &"dodge"
var windup: float = 0.95
var _elapsed: float = 0.0
var _launched: bool = false
var _armed: bool = false
var _cached_target_x: float = 0.0

@onready var attack_area: Area2D = $AttackArea


func setup(target_ref: Node2D, strike_mode: StringName) -> void:
	target = target_ref
	mode = strike_mode


func _process(delta: float) -> void:
	_elapsed += delta
	if target != null and not _launched:
		_cached_target_x = target.global_position.x
		global_position = global_position.lerp(target.global_position + Vector2(220.0, -34.0), clamp(delta * 5.0, 0.0, 1.0))
	elif _launched:
		global_position.x = move_toward(global_position.x, _cached_target_x - 200.0, 980.0 * delta)

	if not _launched and _elapsed >= windup:
		_launched = true
		TimeDirector.request_flash(Color(1.0, 0.22, 0.22, 0.76), 80, 0.16)
		TimeDirector.request_shake(120, 7.0)

	if _launched and not _armed and _elapsed >= windup + 0.04:
		_armed = true
		attack_area.arm({
			"owner_actor": self,
			"damage": 18,
			"attack_name": &"tutorial_strike",
			"knockback": Vector2(-180.0, -42.0),
			"can_be_parried": mode == &"parry"
		})

	if _armed and _elapsed >= windup + 0.18:
		attack_area.deactivate()

	if _elapsed >= windup + 0.34:
		finished.emit()
		queue_free()
	queue_redraw()


func _draw() -> void:
	var telegraph_color := Color(1.0, 0.34, 0.3, 0.28) if mode == &"dodge" else Color(0.9, 0.96, 1.0, 0.28)
	var accent := Color(1.0, 0.28, 0.22, 0.82) if mode == &"dodge" else Color(0.84, 0.96, 1.0, 0.82)
	var radius := 24.0 + sin(_elapsed * 8.0) * 4.0
	draw_circle(Vector2.ZERO, radius, telegraph_color)
	draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 40, accent, 3.0, true)
	draw_line(Vector2(-86.0, 0.0), Vector2(86.0, 0.0), accent, 4.0)
	draw_line(Vector2(48.0, -18.0), Vector2(84.0, 0.0), accent, 3.0)
	draw_line(Vector2(48.0, 18.0), Vector2(84.0, 0.0), accent, 3.0)

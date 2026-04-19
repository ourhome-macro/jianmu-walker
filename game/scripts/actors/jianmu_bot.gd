extends Node2D

@export var follow_distance: Vector2 = Vector2(-88.0, -88.0)

var follow_target: Node2D = null
var disabled: bool = false
var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	if follow_target != null:
		var facing := 1.0
		var facing_value: Variant = follow_target.get("facing")
		if facing_value != null:
			facing = facing_value
		var wobble := Vector2(0.0, sin(_time * 2.4) * 7.0)
		var desired := follow_target.global_position + Vector2(follow_distance.x * -facing, follow_distance.y) + wobble
		if disabled:
			desired += Vector2(0.0, 46.0)
		global_position = global_position.lerp(desired, clamp(delta * 4.0, 0.0, 1.0))
	queue_redraw()


func set_disabled(value: bool) -> void:
	disabled = value


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	var aura_alpha := 0.18 if not disabled else 0.06
	var core_alpha := 0.95 if not disabled else 0.45
	var aura_color := Color(0.18, 0.92, 0.98, aura_alpha)
	var core_color := Color(0.76, 1.0, 1.0, core_alpha)
	draw_circle(Vector2.ZERO, 22.0 + pulse * 2.0, aura_color)
	draw_circle(Vector2.ZERO, 12.0, core_color)
	draw_arc(Vector2.ZERO, 28.0, -0.7, 0.7, 20, Color(0.72, 0.98, 1.0, 0.85), 2.0)
	draw_arc(Vector2.ZERO, 28.0, PI - 0.7, PI + 0.7, 20, Color(0.72, 0.98, 1.0, 0.85), 2.0)
	draw_line(Vector2(-8.0, 20.0), Vector2(8.0, 20.0), Color(0.72, 0.98, 1.0, 0.55), 2.0)

extends Area2D
class_name PortalGate

signal triggered(portal_id: StringName)

@export var portal_id: StringName = &"portal"
@export var accent_color: Color = Color(0.34, 0.84, 1.0, 0.95)

var active: bool = false
var _time: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_active(false)


func _process(delta: float) -> void:
	if not active:
		return
	_time += delta
	queue_redraw()


func set_active(value: bool) -> void:
	active = value
	visible = value
	monitoring = value
	monitorable = value
	if collision_shape != null:
		collision_shape.disabled = not value
	queue_redraw()


func is_active() -> bool:
	return active


func _on_body_entered(body: Node) -> void:
	if not active or not body.is_in_group("player"):
		return
	triggered.emit(portal_id)


func _draw() -> void:
	if not active:
		return
	var pulse := 0.5 + 0.5 * sin(_time * 3.1)
	var outer_radius := 72.0 + pulse * 7.0
	var inner_radius := 42.0 + pulse * 4.0
	draw_arc(Vector2.ZERO, outer_radius, 0.0, TAU, 64, accent_color * Color(1.0, 1.0, 1.0, 0.34), 3.0, true)
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 48, accent_color * Color(1.0, 1.0, 1.0, 0.82), 4.0, true)
	draw_circle(Vector2.ZERO, 22.0 + pulse * 2.0, accent_color * Color(1.0, 1.0, 1.0, 0.14))
	for shard_index in range(8):
		var angle := TAU * float(shard_index) / 8.0 + _time * 0.7
		var from := Vector2.from_angle(angle) * (outer_radius - 10.0)
		var to := Vector2.from_angle(angle) * (outer_radius + 18.0 + pulse * 5.0)
		draw_line(from, to, accent_color * Color(1.0, 1.0, 1.0, 0.7), 2.0)
	for mote_index in range(6):
		var orbit_angle := TAU * float(mote_index) / 6.0 - _time * 1.4
		var orbit_radius := 56.0 + sin(_time * 2.6 + mote_index) * 8.0
		draw_circle(
			Vector2.from_angle(orbit_angle) * orbit_radius,
			3.0 + fmod(mote_index, 2.0),
			accent_color * Color(1.0, 1.0, 1.0, 0.85)
		)

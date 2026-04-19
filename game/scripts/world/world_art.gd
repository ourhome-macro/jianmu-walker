extends Node2D
class_name DemoWorldArt

const ZONE_WIDTH := 1920.0
const ZONE_HEIGHT := 980.0
const GROUND_Y := 596.0

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	_draw_tutorial_zone(0.0)
	_draw_enemy_zone(ZONE_WIDTH)
	_draw_boss_zone(ZONE_WIDTH * 2.0)
	_draw_world_seams()


func _draw_tutorial_zone(origin_x: float) -> void:
	_draw_vertical_gradient(
		Rect2(origin_x, -220.0, ZONE_WIDTH, ZONE_HEIGHT),
		Color(0.93, 0.97, 1.0),
		Color(0.61, 0.86, 0.98)
	)
	_draw_far_mountains(origin_x, Color(0.73, 0.88, 0.96, 0.34), 118.0)
	_draw_far_mountains(origin_x, Color(0.58, 0.82, 0.94, 0.22), 156.0)
	var stream_count := int(round(ZONE_WIDTH / 72.0))
	for stream_index in range(stream_count):
		var x := origin_x + 64.0 + stream_index * 72.0 + sin(_time * 0.8 + stream_index) * 16.0
		var y := 78.0 + fmod(stream_index * 38.0 + _time * 42.0, 320.0)
		draw_line(Vector2(x, y), Vector2(x + 28.0, y), Color(0.28, 0.76, 0.98, 0.28), 2.0)
		draw_line(Vector2(x + 12.0, y - 9.0), Vector2(x + 12.0, y + 9.0), Color(0.28, 0.76, 0.98, 0.18), 2.0)
	_draw_luminous_tree(Vector2(origin_x + 1530.0, GROUND_Y + 10.0), 1.12)
	_draw_data_obelisks(origin_x)
	_draw_ground_block(
		origin_x,
		Color(0.79, 0.89, 0.94, 0.98),
		Color(0.35, 0.74, 0.92, 0.78),
		Color(0.91, 0.97, 1.0, 0.14)
	)


func _draw_enemy_zone(origin_x: float) -> void:
	_draw_vertical_gradient(
		Rect2(origin_x, -220.0, ZONE_WIDTH, ZONE_HEIGHT),
		Color(0.16, 0.11, 0.14),
		Color(0.33, 0.16, 0.1)
	)
	draw_circle(Vector2(origin_x + 1420.0, 146.0), 108.0, Color(1.0, 0.62, 0.34, 0.14))
	_draw_far_mountains(origin_x, Color(0.18, 0.12, 0.14, 0.42), 132.0)
	_draw_far_mountains(origin_x, Color(0.08, 0.06, 0.07, 0.26), 176.0)
	_draw_burned_tree(Vector2(origin_x + 1460.0, GROUND_Y + 18.0), 1.18)
	_draw_ruins(origin_x, Color(0.08, 0.07, 0.08, 0.86))
	for ember_index in range(28):
		var ember_x := origin_x + fmod(ember_index * 86.0 + _time * 18.0, ZONE_WIDTH)
		var ember_y := 180.0 + fmod(ember_index * 23.0 + _time * 31.0, 280.0)
		draw_circle(Vector2(ember_x, ember_y), 2.0, Color(1.0, 0.46, 0.22, 0.16))
	_draw_ground_block(
		origin_x,
		Color(0.12, 0.08, 0.08, 0.98),
		Color(0.52, 0.2, 0.12, 0.82),
		Color(0.98, 0.48, 0.2, 0.08)
	)


func _draw_boss_zone(origin_x: float) -> void:
	_draw_vertical_gradient(
		Rect2(origin_x, -220.0, ZONE_WIDTH, ZONE_HEIGHT),
		Color(0.08, 0.02, 0.04),
		Color(0.2, 0.03, 0.05)
	)
	var halo_center := Vector2(origin_x + 980.0, 142.0)
	draw_circle(halo_center, 120.0, Color(0.98, 0.22, 0.2, 0.08))
	draw_arc(halo_center, 146.0, 0.0, TAU, 72, Color(0.96, 0.2, 0.18, 0.36), 5.0, true)
	for spoke_index in range(14):
		var angle := TAU * float(spoke_index) / 14.0 + _time * 0.1
		draw_line(
			halo_center + Vector2.from_angle(angle) * 164.0,
			halo_center + Vector2.from_angle(angle) * 278.0,
			Color(0.74, 0.14, 0.14, 0.18),
			2.0
		)
	_draw_cyber_tree(Vector2(origin_x + 1500.0, GROUND_Y + 20.0), 1.3)
	_draw_spires(origin_x)
	_draw_ground_block(
		origin_x,
		Color(0.07, 0.03, 0.04, 0.98),
		Color(0.95, 0.18, 0.15, 0.86),
		Color(0.98, 0.18, 0.16, 0.1)
	)


func _draw_vertical_gradient(area: Rect2, top: Color, bottom: Color) -> void:
	var steps := 28
	for step in range(steps):
		var ratio := float(step) / float(steps - 1)
		var color := top.lerp(bottom, ratio)
		var y := area.position.y + area.size.y * ratio
		draw_rect(Rect2(area.position.x, y, area.size.x, area.size.y / float(steps) + 2.0), color, true)


func _draw_far_mountains(origin_x: float, color: Color, peak_offset: float) -> void:
	var right := origin_x + ZONE_WIDTH + 40.0
	var polygon := PackedVector2Array([
		Vector2(origin_x - 40.0, GROUND_Y - 84.0),
		Vector2(origin_x + ZONE_WIDTH * 0.14, GROUND_Y - peak_offset),
		Vector2(origin_x + ZONE_WIDTH * 0.31, GROUND_Y - 96.0),
		Vector2(origin_x + ZONE_WIDTH * 0.50, GROUND_Y - peak_offset - 22.0),
		Vector2(origin_x + ZONE_WIDTH * 0.68, GROUND_Y - 92.0),
		Vector2(origin_x + ZONE_WIDTH * 0.86, GROUND_Y - peak_offset + 18.0),
		Vector2(right, GROUND_Y - 84.0),
		Vector2(right, GROUND_Y + 60.0),
		Vector2(origin_x - 40.0, GROUND_Y + 60.0)
	])
	draw_colored_polygon(polygon, color)


func _draw_ground_block(origin_x: float, fill: Color, edge: Color, detail: Color) -> void:
	draw_rect(Rect2(origin_x, GROUND_Y, ZONE_WIDTH, 190.0), fill, true)
	draw_line(Vector2(origin_x, GROUND_Y), Vector2(origin_x + ZONE_WIDTH, GROUND_Y), edge, 5.0)
	for crack_index in range(8):
		var start_x := origin_x + 90.0 + crack_index * 132.0 + sin(_time * 0.4 + crack_index) * 8.0
		draw_polyline(
			PackedVector2Array([
				Vector2(start_x, GROUND_Y + 22.0),
				Vector2(start_x + 18.0, GROUND_Y + 46.0),
				Vector2(start_x - 8.0, GROUND_Y + 78.0),
				Vector2(start_x + 12.0, GROUND_Y + 108.0)
			]),
			detail,
			2.0,
			true
		)
	for band_index in range(4):
		draw_rect(
			Rect2(origin_x, GROUND_Y + 30.0 + band_index * 34.0, ZONE_WIDTH, 8.0),
			detail * Color(1.0, 1.0, 1.0, 0.54),
			true
		)


func _draw_luminous_tree(base: Vector2, scale_value: float) -> void:
	var trunk := PackedVector2Array([
		base + Vector2(-44.0, 0.0) * scale_value,
		base + Vector2(-24.0, -178.0) * scale_value,
		base + Vector2(-12.0, -286.0) * scale_value,
		base + Vector2(12.0, -296.0) * scale_value,
		base + Vector2(28.0, -188.0) * scale_value,
		base + Vector2(48.0, 0.0) * scale_value
	])
	draw_colored_polygon(trunk, Color(0.12, 0.44, 0.58, 0.86))
	for branch_index in range(7):
		var branch_y := base.y - (110.0 + branch_index * 38.0) * scale_value
		var sway := sin(_time * 0.7 + branch_index) * 9.0
		draw_line(
			Vector2(base.x + sway, branch_y),
			Vector2(base.x + (120.0 + branch_index * 34.0) * scale_value, branch_y - (52.0 + branch_index * 18.0) * scale_value),
			Color(0.14, 0.54, 0.72, 0.9),
			6.0 - branch_index * 0.5
		)
		draw_line(
			Vector2(base.x - sway, branch_y + 8.0),
			Vector2(base.x - (138.0 + branch_index * 28.0) * scale_value, branch_y - (38.0 + branch_index * 20.0) * scale_value),
			Color(0.14, 0.54, 0.72, 0.9),
			6.0 - branch_index * 0.5
		)
		draw_circle(Vector2(base.x + sway, branch_y), 8.0 + branch_index * 1.2, Color(0.72, 0.98, 1.0, 0.22))
	for symbol_index in range(18):
		var symbol_x := base.x - 220.0 + symbol_index * 26.0
		var symbol_y := base.y - 300.0 + sin(_time * 1.4 + symbol_index) * 18.0
		draw_line(Vector2(symbol_x, symbol_y), Vector2(symbol_x + 10.0, symbol_y), Color(0.78, 0.98, 1.0, 0.22), 2.0)


func _draw_burned_tree(base: Vector2, scale_value: float) -> void:
	var trunk := PackedVector2Array([
		base + Vector2(-40.0, 0.0) * scale_value,
		base + Vector2(-18.0, -164.0) * scale_value,
		base + Vector2(-6.0, -248.0) * scale_value,
		base + Vector2(14.0, -244.0) * scale_value,
		base + Vector2(32.0, -148.0) * scale_value,
		base + Vector2(46.0, 0.0) * scale_value
	])
	draw_colored_polygon(trunk, Color(0.05, 0.04, 0.04, 0.94))
	for branch_index in range(6):
		var branch_y := base.y - (96.0 + branch_index * 34.0) * scale_value
		draw_line(
			Vector2(base.x, branch_y),
			Vector2(base.x + (108.0 + branch_index * 22.0) * scale_value, branch_y - (42.0 + branch_index * 20.0) * scale_value),
			Color(0.06, 0.05, 0.05, 0.92),
			5.5 - branch_index * 0.45
		)
		draw_line(
			Vector2(base.x + 6.0, branch_y + 8.0),
			Vector2(base.x - (124.0 + branch_index * 26.0) * scale_value, branch_y - (24.0 + branch_index * 16.0) * scale_value),
			Color(0.06, 0.05, 0.05, 0.92),
			5.5 - branch_index * 0.45
		)
		draw_circle(Vector2(base.x + 20.0 * sin(branch_index), branch_y), 6.0, Color(0.92, 0.26, 0.12, 0.18))
	for ember_index in range(14):
		var ember_pos := Vector2(
			base.x - 160.0 + ember_index * 26.0,
			base.y - 124.0 - fmod(ember_index * 11.0 + _time * 18.0, 110.0)
		)
		draw_circle(ember_pos, 2.0, Color(0.96, 0.42, 0.2, 0.26))


func _draw_cyber_tree(base: Vector2, scale_value: float) -> void:
	var trunk := PackedVector2Array([
		base + Vector2(-54.0, 0.0) * scale_value,
		base + Vector2(-28.0, -174.0) * scale_value,
		base + Vector2(-10.0, -314.0) * scale_value,
		base + Vector2(14.0, -322.0) * scale_value,
		base + Vector2(38.0, -182.0) * scale_value,
		base + Vector2(58.0, 0.0) * scale_value
	])
	draw_colored_polygon(trunk, Color(0.05, 0.02, 0.03, 0.96))
	for cable_index in range(8):
		var branch_y := base.y - (96.0 + cable_index * 34.0) * scale_value
		var cable_sway := sin(_time * 0.9 + cable_index) * 14.0
		draw_polyline(
			PackedVector2Array([
				Vector2(base.x + cable_sway, branch_y),
				Vector2(base.x + 56.0 * scale_value, branch_y - 18.0),
				Vector2(base.x + (148.0 + cable_index * 24.0) * scale_value, branch_y - (58.0 + cable_index * 16.0) * scale_value)
			]),
			Color(0.86, 0.18, 0.16, 0.84),
			4.0,
			true
		)
		draw_polyline(
			PackedVector2Array([
				Vector2(base.x - cable_sway, branch_y + 8.0),
				Vector2(base.x - 46.0 * scale_value, branch_y - 12.0),
				Vector2(base.x - (164.0 + cable_index * 22.0) * scale_value, branch_y - (44.0 + cable_index * 18.0) * scale_value)
			]),
			Color(0.6, 0.08, 0.1, 0.82),
			4.0,
			true
		)
		draw_circle(Vector2(base.x + cable_sway, branch_y), 6.0 + cable_index * 0.9, Color(1.0, 0.22, 0.18, 0.16))


func _draw_data_obelisks(origin_x: float) -> void:
	for obelisk_index in range(6):
		var x := origin_x + 170.0 + obelisk_index * 190.0
		var height := 150.0 + obelisk_index * 22.0
		var points := PackedVector2Array([
			Vector2(x, GROUND_Y),
			Vector2(x + 24.0, GROUND_Y - height),
			Vector2(x + 52.0, GROUND_Y)
		])
		draw_colored_polygon(points, Color(0.16, 0.52, 0.68, 0.42))
		draw_line(Vector2(x + 26.0, GROUND_Y - height), Vector2(x + 26.0, GROUND_Y - 10.0), Color(0.82, 0.98, 1.0, 0.26), 2.0)


func _draw_ruins(origin_x: float, color: Color) -> void:
	for pillar_index in range(7):
		var x := origin_x + 124.0 + pillar_index * 246.0
		var height := 144.0 + fmod(pillar_index * 31.0, 84.0)
		draw_rect(Rect2(x, GROUND_Y - height, 28.0, height), color, true)
		draw_rect(Rect2(x - 12.0, GROUND_Y - height - 16.0, 52.0, 16.0), color, true)


func _draw_spires(origin_x: float) -> void:
	for spire_index in range(8):
		var x := origin_x + 130.0 + spire_index * 224.0
		var height := 148.0 + fmod(spire_index * 18.0, 88.0)
		var polygon := PackedVector2Array([
			Vector2(x, GROUND_Y + 4.0),
			Vector2(x + 22.0, GROUND_Y - height),
			Vector2(x + 52.0, GROUND_Y + 4.0)
		])
		draw_colored_polygon(polygon, Color(0.16, 0.04, 0.06, 0.9))
		draw_line(Vector2(x + 22.0, GROUND_Y - height), Vector2(x + 22.0, GROUND_Y - 12.0), Color(1.0, 0.22, 0.18, 0.32), 2.0)


func _draw_world_seams() -> void:
	for seam_x in [ZONE_WIDTH, ZONE_WIDTH * 2.0]:
		draw_rect(Rect2(seam_x - 10.0, -120.0, 20.0, 820.0), Color(0.02, 0.03, 0.05, 0.18), true)
		draw_line(Vector2(seam_x, 0.0), Vector2(seam_x, GROUND_Y + 120.0), Color(0.82, 0.92, 1.0, 0.08), 2.0)

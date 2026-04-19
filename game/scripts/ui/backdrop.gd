extends Control

const COLLAPSE_CITY_SEQUENCES := [
	"res://assets/backgrounds/collapse_cities/qiaodu/qiaodu_",
	"res://assets/backgrounds/collapse_cities/shiduanlu/shiduanlu_",
	"res://assets/backgrounds/collapse_cities/longxi/longxi_",
	"res://assets/backgrounds/collapse_cities/jincheng/jincheng_"
]
const COLLAPSE_CITY_FPS := 12.0

var stage_name: StringName = &"tutorial"
var collapse_progress: float = 0.0
var collapse_city_index: int = 0
var _time: float = 0.0
var _collapse_city_frames: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_collapse_city_frames()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func set_stage(new_stage: StringName) -> void:
	stage_name = new_stage
	queue_redraw()


func set_collapse_progress(value: float) -> void:
	collapse_progress = clamp(value, 0.0, 1.0)
	queue_redraw()


func set_collapse_city(index: int) -> void:
	if _collapse_city_frames.is_empty():
		collapse_city_index = 0
	else:
		collapse_city_index = clampi(index, 0, _collapse_city_frames.size() - 1)
	queue_redraw()


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	match stage_name:
		&"tutorial":
			_draw_tutorial(viewport_size)
		&"enemy":
			_draw_enemy(viewport_size)
		&"boss":
			_draw_boss(viewport_size)
		&"collapse":
			_draw_collapse(viewport_size)
		&"ending":
			_draw_ending(viewport_size)
		_:
			_draw_tutorial(viewport_size)


func _draw_tutorial(viewport_size: Vector2) -> void:
	_draw_vertical_gradient(viewport_size, Color(0.92, 0.97, 1.0, 0.12), Color(0.62, 0.86, 0.98, 0.22))
	_draw_overlay_ring(viewport_size, Color(0.34, 0.78, 0.98, 0.32))
	for index in range(18):
		var x := fmod(index * 74.0 + _time * 54.0, viewport_size.x)
		var y := 38.0 + fmod(index * 29.0 + _time * 18.0, viewport_size.y * 0.62)
		draw_line(Vector2(x, y), Vector2(x + 16.0, y), Color(0.36, 0.8, 0.98, 0.12), 2.0)


func _draw_enemy(viewport_size: Vector2) -> void:
	_draw_vertical_gradient(viewport_size, Color(0.14, 0.08, 0.08, 0.14), Color(0.42, 0.16, 0.1, 0.26))
	_draw_overlay_ring(viewport_size, Color(0.96, 0.46, 0.22, 0.18))
	for mote_index in range(24):
		var x := fmod(mote_index * 74.0 + _time * 18.0, viewport_size.x)
		var y := viewport_size.y * 0.26 + fmod(mote_index * 31.0 + _time * 23.0, viewport_size.y * 0.5)
		draw_circle(Vector2(x, y), 1.8, Color(1.0, 0.48, 0.22, 0.14))


func _draw_boss(viewport_size: Vector2) -> void:
	_draw_vertical_gradient(viewport_size, Color(0.16, 0.03, 0.05, 0.2), Color(0.24, 0.04, 0.06, 0.3))
	var halo_center := Vector2(viewport_size.x * 0.5, viewport_size.y * 0.3)
	draw_circle(halo_center, 130.0, Color(0.98, 0.22, 0.18, 0.08))
	draw_arc(halo_center, 150.0, 0.0, TAU, 72, Color(0.94, 0.18, 0.16, 0.36), 5.0, true)
	for spoke in range(12):
		var angle := TAU * float(spoke) / 12.0 + _time * 0.12
		var from := halo_center + Vector2.from_angle(angle) * 136.0
		var to := halo_center + Vector2.from_angle(angle) * 240.0
		draw_line(from, to, Color(0.72, 0.12, 0.12, 0.14), 2.0)


func _draw_collapse(viewport_size: Vector2) -> void:
	var palettes := [
		{
			"top": Color(0.1, 0.18, 0.26, 0.52),
			"bottom": Color(0.07, 0.28, 0.35, 0.26),
			"accent": Color(0.52, 0.9, 1.0, 0.34),
			"mist": Color(0.72, 0.9, 1.0, 0.18)
		},
		{
			"top": Color(0.24, 0.16, 0.09, 0.5),
			"bottom": Color(0.4, 0.28, 0.12, 0.26),
			"accent": Color(0.98, 0.74, 0.38, 0.34),
			"mist": Color(0.98, 0.86, 0.62, 0.16)
		},
		{
			"top": Color(0.1, 0.2, 0.16, 0.48),
			"bottom": Color(0.16, 0.3, 0.24, 0.24),
			"accent": Color(0.76, 0.96, 0.9, 0.3),
			"mist": Color(0.88, 1.0, 0.96, 0.16)
		},
		{
			"top": Color(0.2, 0.08, 0.07, 0.54),
			"bottom": Color(0.36, 0.12, 0.1, 0.28),
			"accent": Color(1.0, 0.46, 0.26, 0.36),
			"mist": Color(1.0, 0.78, 0.58, 0.14)
		}
	]
	var palette_index := mini(int(floor(collapse_progress * palettes.size())), palettes.size() - 1)
	if not _collapse_city_frames.is_empty():
		palette_index = clampi(collapse_city_index, 0, palettes.size() - 1)
	var palette = palettes[palette_index]
	var has_city_frame := _draw_collapse_city_frame(viewport_size)
	if has_city_frame:
		_draw_vertical_gradient(
			viewport_size,
			palette["top"] * Color(1.0, 1.0, 1.0, 0.42),
			palette["bottom"] * Color(1.0, 1.0, 1.0, 0.26)
		)
	else:
		_draw_vertical_gradient(viewport_size, palette["top"], palette["bottom"])
	for ribbon in range(9):
		var y_ratio := 0.16 + float(ribbon) * 0.075
		_draw_flowing_ribbon(
			viewport_size,
			palette["accent"] * Color(1.0, 1.0, 1.0, 0.42 - ribbon * 0.03),
			y_ratio,
			22.0 + ribbon * 3.0,
			0.7 + ribbon * 0.08,
			4.0 - ribbon * 0.22
		)
	for cloud in range(18):
		var cloud_x := fmod(cloud * 96.0 + _time * (14.0 + cloud * 0.6), viewport_size.x + 260.0) - 130.0
		var cloud_y := viewport_size.y * 0.12 + fmod(cloud * 31.0 + _time * 8.0, viewport_size.y * 0.72)
		var radius := 28.0 + fmod(cloud * 7.0, 22.0)
		draw_circle(Vector2(cloud_x, cloud_y), radius, palette["mist"] * Color(1.0, 1.0, 1.0, 0.22))
	for stroke in range(14):
		var sx := fmod(stroke * 122.0 + _time * 65.0, viewport_size.x + 160.0) - 80.0
		var sy := viewport_size.y * 0.22 + fmod(stroke * 43.0 + _time * 40.0, viewport_size.y * 0.6)
		draw_polyline(
			PackedVector2Array([
				Vector2(sx - 24.0, sy + 10.0),
				Vector2(sx + 8.0, sy - 8.0),
				Vector2(sx + 40.0, sy + 12.0)
			]),
			palette["accent"] * Color(1.0, 1.0, 1.0, 0.38),
			2.2,
			true
		)


func _draw_collapse_city_frame(viewport_size: Vector2) -> bool:
	if _collapse_city_frames.is_empty():
		return false
	var city_index := clampi(collapse_city_index, 0, _collapse_city_frames.size() - 1)
	var frames: Array = _collapse_city_frames[city_index]
	if frames.is_empty():
		return false
	var frame_index: int = int(floor(_time * COLLAPSE_CITY_FPS)) % frames.size()
	var texture := frames[frame_index] as Texture2D
	if texture == null:
		return false
	draw_texture_rect(texture, Rect2(Vector2.ZERO, viewport_size), false)
	return true


func _load_collapse_city_frames() -> void:
	_collapse_city_frames.clear()
	for prefix in COLLAPSE_CITY_SEQUENCES:
		var frames: Array = []
		var frame_number := 1
		while frame_number <= 120:
			var texture_path := "%s%02d.png" % [prefix, frame_number]
			if not ResourceLoader.exists(texture_path):
				break
			var texture := load(texture_path) as Texture2D
			if texture != null:
				frames.append(texture)
			frame_number += 1
		_collapse_city_frames.append(frames)


func _draw_ending(viewport_size: Vector2) -> void:
	_draw_vertical_gradient(viewport_size, Color(0.02, 0.08, 0.14, 0.44), Color(0.04, 0.22, 0.24, 0.22))
	var planet_center := Vector2(viewport_size.x * 0.5, viewport_size.y * 0.58)
	draw_circle(planet_center, 190.0, Color(0.14, 0.58, 0.52, 0.34))
	draw_circle(planet_center + Vector2(-34.0, -42.0), 150.0, Color(0.28, 0.78, 0.7, 0.18))
	for star in range(26):
		var x := fmod(star * 61.0 + _time * 12.0, viewport_size.x)
		var y := 40.0 + fmod(star * 37.0 + _time * 8.0, viewport_size.y * 0.42)
		draw_circle(Vector2(x, y), 1.8 + fmod(star, 2.0), Color(0.82, 1.0, 0.94, 0.42))


func _draw_vertical_gradient(viewport_size: Vector2, top: Color, bottom: Color) -> void:
	var steps := 32
	for step in range(steps):
		var ratio := float(step) / float(steps - 1)
		var color := top.lerp(bottom, ratio)
		var y := viewport_size.y * ratio
		draw_rect(Rect2(0.0, y, viewport_size.x, viewport_size.y / float(steps) + 1.0), color, true)


func _draw_overlay_ring(viewport_size: Vector2, color: Color) -> void:
	var center := Vector2(viewport_size.x * 0.5, viewport_size.y * 0.42)
	draw_circle(center, 170.0 + sin(_time * 1.7) * 8.0, color * Color(1.0, 1.0, 1.0, 0.4))
	draw_arc(center, 188.0, 0.0, TAU, 64, color, 3.0, true)


func _draw_flowing_ribbon(
	viewport_size: Vector2,
	color: Color,
	y_ratio: float,
	amplitude: float,
	speed: float,
	width: float
) -> void:
	var points := PackedVector2Array()
	var y_base := viewport_size.y * y_ratio
	for step in range(20):
		var x := -80.0 + step * ((viewport_size.x + 160.0) / 19.0)
		var wave := sin(_time * speed + step * 0.62) * amplitude
		var drift := cos(_time * speed * 0.6 + step * 0.31) * amplitude * 0.45
		points.append(Vector2(x, y_base + wave + drift))
	draw_polyline(points, color, width, true)

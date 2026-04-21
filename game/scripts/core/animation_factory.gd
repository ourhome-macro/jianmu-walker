extends RefCounted
class_name AnimationFactory


static func build_player_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var idle_loaded := false
	for idle_path in ["res://assets/player/waepon idle.png", "res://assets/player/weapon idle.png"]:
		if _add_single_frame(frames, &"idle", idle_path, 2.0, true):
			idle_loaded = true
			break
	if not idle_loaded:
		_add_sequence(frames, &"idle", "res://assets/player/move/player_move_", 1, 1, 2.0, true)
	_add_sequence(frames, &"move", "res://assets/player/move/player_move_", 1, 7, 11.0, true)
	if _sequence_exists("res://assets/player/attack_sheet_split/attack_sheet_%02d.png", 1, 8):
		_add_sequence(frames, &"attack_1", "res://assets/player/attack_sheet_split/attack_sheet_", 1, 4, 12.0, false)
		_add_sequence(frames, &"attack_2", "res://assets/player/attack_sheet_split/attack_sheet_", 3, 6, 13.0, false)
		_add_sequence(frames, &"attack_3", "res://assets/player/attack_sheet_split/attack_sheet_", 5, 8, 14.0, false)
	elif ResourceLoader.exists("res://assets/player/Attack - 副本.png"):
		_add_sheet_slice(frames, &"attack_1", "res://assets/player/Attack - 副本.png", Vector2i(256, 128), 0, 4, 12.0, false)
		_add_sheet_slice(frames, &"attack_2", "res://assets/player/Attack - 副本.png", Vector2i(256, 128), 2, 4, 13.0, false)
		_add_sheet_slice(frames, &"attack_3", "res://assets/player/Attack - 副本.png", Vector2i(256, 128), 4, 4, 14.0, false)
	else:
		_add_sequence(frames, &"attack_1", "res://assets/player/attack_1/player_attack_1_", 1, 6, 14.0, false)
		_add_sequence(frames, &"attack_2", "res://assets/player/attack_2/player_attack_2_", 1, 9, 13.0, false)
		_add_sequence(frames, &"attack_3", "res://assets/player/attack_2/player_attack_2_", 3, 9, 17.0, false)
	if _sequence_exists("res://assets/player/jump/player_jump_%02d.png", 1, 11):
		_add_sequence(frames, &"jump_start", "res://assets/player/jump/player_jump_", 1, 4, 18.0, false)
		_add_sequence(frames, &"jump_rise", "res://assets/player/jump/player_jump_", 5, 8, 10.0, true)
		_add_sequence(frames, &"jump_fall", "res://assets/player/jump/player_jump_", 9, 11, 10.0, true)
	else:
		_add_sequence(frames, &"jump_start", "res://assets/player/move/player_move_", 1, 2, 8.0, false)
		_add_sequence(frames, &"jump_rise", "res://assets/player/move/player_move_", 3, 4, 8.0, true)
		_add_sequence(frames, &"jump_fall", "res://assets/player/move/player_move_", 6, 7, 8.0, true)
	if _sequence_exists("res://assets/player/dodge/player_dodge_%02d.png", 1, 5):
		_add_sequence(frames, &"dodge", "res://assets/player/dodge/player_dodge_", 1, 5, 18.0, false)
	else:
		_add_sequence(frames, &"dodge", "res://assets/player/move/player_move_", 2, 7, 20.0, false)
	_add_sequence(frames, &"guard_raise", "res://assets/player/parry/player_parry_", 1, 3, 16.0, false)
	_add_sequence(frames, &"guard_hold", "res://assets/player/parry/player_parry_", 4, 4, 1.0, true)
	_add_sequence(frames, &"parry", "res://assets/player/parry/player_parry_", 1, 9, 18.0, false)
	_add_sequence(frames, &"hurt", "res://assets/player/attack_1/player_attack_1_", 3, 4, 8.0, false)
	_add_sequence(frames, &"dead", "res://assets/player/parry/player_parry_", 9, 9, 1.0, false)
	return frames


static func build_enemy_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	_add_sheet(frames, &"idle", "res://assets/enemy/enemy_idle_sheet.png", Vector2i(128, 128), 1, 2.0, true)
	_add_sheet(frames, &"walk", "res://assets/enemy/enemy_walk_sheet.png", Vector2i(128, 128), 7, 10.0, true)
	_add_sheet(frames, &"attack_1", "res://assets/enemy/enemy_attack_1_sheet.png", Vector2i(128, 128), 4, 11.0, false)
	_add_sheet(frames, &"attack_2", "res://assets/enemy/enemy_attack_2_sheet.png", Vector2i(128, 128), 4, 11.0, false)
	_add_sheet(frames, &"lunge", "res://assets/enemy/enemy_lunge_sheet.png", Vector2i(128, 128), 5, 12.0, false)
	_add_sheet(frames, &"dead", "res://assets/enemy/enemy_dead_sheet.png", Vector2i(128, 128), 5, 8.0, false)
	return frames


static func build_boss_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	_add_sequence(frames, &"idle", "res://assets/boss/walk/boss_walk_", 1, 1, 1.0, true)
	_add_sequence(frames, &"chase", "res://assets/boss/walk/boss_walk_", 8, 15, 12.0, true)
	_add_sequence(frames, &"sweep", "res://assets/boss/attack/boss_attack_", 1, 7, 12.0, false)
	_add_sequence(frames, &"grab", "res://assets/boss/attack/boss_attack_", 1, 7, 16.0, false)
	_add_sequence(frames, &"slam", "res://assets/boss/slam/boss_slam_", 1, 19, 13.0, false)
	_add_sequence(frames, &"jump", "res://assets/boss/slam/boss_slam_", 1, 19, 15.0, false)
	_add_sequence(frames, &"burst", "res://assets/boss/attack/boss_attack_", 1, 7, 9.0, false)
	_add_sequence(frames, &"dead", "res://assets/boss/death/boss_death_", 1, 12, 10.0, false)
	return frames


static func build_boom_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	_add_sequence(frames, &"boom", "res://assets/fx/boom/boom_", 1, 9, 18.0, false)
	return frames


static func build_burst_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	_add_sequence(frames, &"burst", "res://assets/fx/boss_burst/boss_burst_", 1, 32, 16.0, false)
	return frames


static func _add_single_frame(
	frames: SpriteFrames,
	animation_name: StringName,
	texture_path: String,
	fps: float,
	loop: bool
) -> bool:
	var texture := load(texture_path) as Texture2D
	if texture == null:
		return false
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop)
	frames.add_frame(animation_name, texture)
	return true


static func _add_sequence(
	frames: SpriteFrames,
	animation_name: StringName,
	path_prefix: String,
	first_index: int,
	last_index: int,
	fps: float,
	loop: bool
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop)
	for index in range(first_index, last_index + 1):
		var texture := load("%s%02d.png" % [path_prefix, index]) as Texture2D
		if texture != null:
			frames.add_frame(animation_name, texture)


static func _add_sheet(
	frames: SpriteFrames,
	animation_name: StringName,
	texture_path: String,
	frame_size: Vector2i,
	frame_count: int,
	fps: float,
	loop: bool
) -> void:
	var atlas_texture := load(texture_path) as Texture2D
	if atlas_texture == null:
		return
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop)
	for frame_index in range(frame_count):
		var region_texture := AtlasTexture.new()
		region_texture.atlas = atlas_texture
		region_texture.region = Rect2(
			Vector2(frame_index * frame_size.x, 0),
			Vector2(frame_size.x, frame_size.y)
		)
		frames.add_frame(animation_name, region_texture)


static func _add_sheet_slice(
	frames: SpriteFrames,
	animation_name: StringName,
	texture_path: String,
	frame_size: Vector2i,
	start_frame: int,
	frame_count: int,
	fps: float,
	loop: bool
) -> void:
	var atlas_texture := load(texture_path) as Texture2D
	if atlas_texture == null:
		return
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop)
	for frame_offset in range(frame_count):
		var frame_index := start_frame + frame_offset
		var region_texture := AtlasTexture.new()
		region_texture.atlas = atlas_texture
		region_texture.region = Rect2(
			Vector2(frame_index * frame_size.x, 0),
			Vector2(frame_size.x, frame_size.y)
		)
		frames.add_frame(animation_name, region_texture)


static func _sequence_exists(path_pattern: String, first_index: int, last_index: int) -> bool:
	for index in range(first_index, last_index + 1):
		if not ResourceLoader.exists(path_pattern % index):
			return false
	return true

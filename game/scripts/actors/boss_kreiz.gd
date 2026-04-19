extends CharacterBody2D

const AnimationFactoryRef = preload("res://scripts/core/animation_factory.gd")
const BOSS_ATTACK_SFX_CANDIDATES := [
	"res://assets/audio/boss atk.mp3",
	"res://assets/audio/boss_attack.mp3"
]
const BOSS_BURST_SFX_CANDIDATES := [
	"res://assets/audio/boss大招.mp3",
	"res://assets/audio/boss澶ф嫑.mp3",
	"res://assets/audio/boss_burst.mp3"
]

signal hp_changed(current_hp: int, max_hp: int)
signal phase_changed(phase: int)
signal defeated

const GRAVITY := 2400.0

enum State {
	IDLE,
	CHASE,
	FEINT,
	SWEEP,
	SLAM,
	JUMP,
	GRAB,
	BURST,
	STUN,
	HURT,
	DEAD
}

@export var max_hp: int = 240
@export var move_speed: float = 84.0
@export var attack_range: float = 126.0
@export var detect_range: float = 540.0
@export var attack_cooldown_ms: int = 1600
@export var visual_scale: float = 1.22
@export var visual_foot_y: float = 16.0
@export var feint_probability: float = 0.4
@export var close_combo_threshold: float = 132.0
@export var mid_combo_threshold: float = 228.0
@export var far_jump_trigger_distance: float = 286.0
@export var far_jump_trigger_chance: float = 0.36
@export var combo_link_window_ms: int = 780
@export var fast_recovery_ms: int = 360
@export var slow_recovery_ms: int = 560
@export var jump_takeoff_ms: int = 390
@export var jump_travel_ms: int = 700
@export var jump_arc_height: float = 148.0
@export var min_turn_interval_ms: int = 150
@export var turn_dead_zone: float = 28.0
@export var poise_window_ms: int = 3200
@export var poise_hits_required: int = 8
@export var poise_stun_ms: int = 720
@export var poise_stun_cooldown_ms: int = 2600

var hp: int = max_hp
var facing: float = -1.0
var phase: int = 1
var state: State = State.IDLE
var player_ref: Node2D = null
var active: bool = false
var next_attack_ms: int = 0
var _flash_timer: float = 0.0
var _stun_until_ms: int = 0
var _jump_started_ms: int = 0
var _jump_target_x: float = 0.0
var _jump_origin_x: float = 0.0
var _jump_travel_duration_ms: int = 700
var _burst_flash_armed: bool = false
var _combo_step: int = 0
var _combo_active_until_ms: int = 0
var _feint_followup_attack: StringName = &""
var _feint_release_ms: int = 0
var _is_fake_attack: bool = false
var _jump_visual_lift: float = 0.0
var _base_visual_position: Vector2 = Vector2.ZERO
var _chase_frame_offsets: Array[Vector2] = []
var _idle_offset: Vector2 = Vector2.ZERO
var _current_frame_offset: Vector2 = Vector2.ZERO
var _active_fx: Array[AnimatedSprite2D] = []
var _burst_fx_frames: SpriteFrames = AnimationFactoryRef.build_burst_frames()
var _boom_frames: SpriteFrames = AnimationFactoryRef.build_boom_frames()
var _next_turn_allowed_ms: int = 0
var _poise_window_start_ms: int = 0
var _poise_hits_in_window: int = 0
var _next_poise_stun_allowed_ms: int = 0
var _last_attack_used: StringName = &""
var _last_attack_used_ms: int = -10_000
var _last_feint_ms: int = -10_000

@onready var visual: AnimatedSprite2D = $Visual
@onready var attack_area: Area2D = $AttackArea
@onready var _attack_sfx_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
@onready var _burst_sfx_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()


func _ready() -> void:
	add_to_group("enemy_actor")
	visual.sprite_frames = AnimationFactoryRef.build_boss_frames()
	_apply_visual_scale()
	_build_walk_alignment()
	_refresh_visual_alignment()
	visual.play(&"idle")
	visual.frame_changed.connect(_on_visual_frame_changed)
	visual.animation_finished.connect(_on_visual_animation_finished)
	attack_area.hit_target.connect(_on_attack_hit_target)
	$Hurtbox.add_to_group("hurtbox")
	add_child(_attack_sfx_player)
	add_child(_burst_sfx_player)
	_attack_sfx_player.stream = _load_first_stream(BOSS_ATTACK_SFX_CANDIDATES)
	_attack_sfx_player.volume_db = -1.2
	_burst_sfx_player.stream = _load_first_stream(BOSS_BURST_SFX_CANDIDATES)
	_burst_sfx_player.volume_db = -0.2
	emit_hp_changed()


func _apply_visual_scale() -> void:
	visual.scale = Vector2.ONE * visual_scale
	_base_visual_position = Vector2(0.0, visual_foot_y - (64.0 * visual_scale))
	_jump_visual_lift = 0.0
	_apply_visual_transform()


func _build_walk_alignment() -> void:
	_chase_frame_offsets.clear()
	_idle_offset = Vector2.ZERO
	if visual.sprite_frames == null:
		return
	var chase_count := visual.sprite_frames.get_frame_count(&"chase")
	if chase_count <= 0:
		return
	var ref_anchor := _get_texture_anchor(visual.sprite_frames.get_frame_texture(&"chase", 0))
	for frame_idx in range(chase_count):
		var frame_texture := visual.sprite_frames.get_frame_texture(&"chase", frame_idx)
		_chase_frame_offsets.append(_calculate_alignment_offset(ref_anchor, frame_texture))
	_idle_offset = _calculate_alignment_offset(ref_anchor, visual.sprite_frames.get_frame_texture(&"idle", 0))


func _get_texture_anchor(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2(256.0, 128.0)
	var image := texture.get_image()
	if image == null or image.is_empty():
		return Vector2(256.0, 128.0)
	var used_rect := image.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return Vector2(float(image.get_width()) * 0.5, float(image.get_height()))
	var center_x: float = float(used_rect.position.x) + float(used_rect.size.x) * 0.5
	var bottom_y: float = float(used_rect.position.y + used_rect.size.y)
	return Vector2(center_x, bottom_y)


func _calculate_alignment_offset(reference_anchor: Vector2, texture: Texture2D) -> Vector2:
	var anchor := _get_texture_anchor(texture)
	return reference_anchor - anchor


func _refresh_visual_alignment() -> void:
	if state == State.JUMP:
		_current_frame_offset = Vector2.ZERO
		_apply_visual_transform()
		return
	match visual.animation:
		&"chase":
			if visual.frame >= 0 and visual.frame < _chase_frame_offsets.size():
				_current_frame_offset = _chase_frame_offsets[visual.frame]
			else:
				_current_frame_offset = Vector2.ZERO
		&"idle":
			_current_frame_offset = _idle_offset
		_:
			_current_frame_offset = Vector2.ZERO
	_apply_visual_transform()


func _apply_visual_transform() -> void:
	visual.position = _base_visual_position + Vector2(0.0, _jump_visual_lift)
	visual.offset = _current_frame_offset


func activate(player: Node2D) -> void:
	player_ref = player
	active = true
	state = State.IDLE
	_reset_combat_flow()
	next_attack_ms = Time.get_ticks_msec() + 900
	visual.speed_scale = 1.0
	visual.play(&"idle")
	_refresh_visual_alignment()


func _reset_combat_flow() -> void:
	_combo_step = 0
	_combo_active_until_ms = 0
	_feint_followup_attack = &""
	_feint_release_ms = 0
	_is_fake_attack = false
	_jump_visual_lift = 0.0
	visual.speed_scale = 1.0
	_next_turn_allowed_ms = 0
	_poise_window_start_ms = Time.get_ticks_msec()
	_poise_hits_in_window = 0
	_next_poise_stun_allowed_ms = 0
	_last_attack_used = &""
	_last_attack_used_ms = -10_000
	_last_feint_ms = -10_000


func emit_hp_changed() -> void:
	hp_changed.emit(hp, max_hp)


func receive_hit(hit_data: Dictionary) -> void:
	if state == State.DEAD:
		return
	var now := Time.get_ticks_msec()
	var damage: int = int(hit_data.get("damage", 16))
	hp = max(hp - damage, 0)
	emit_hp_changed()
	_flash_timer = 0.18
	_register_poise_hit(now)
	_update_phase()
	if hp <= 0:
		_die()
		return
	if _can_break_poise(now):
		_enter_poise_stun(now)


func _register_poise_hit(now: int) -> void:
	if now - _poise_window_start_ms > poise_window_ms:
		_poise_window_start_ms = now
		_poise_hits_in_window = 0
	_poise_hits_in_window += 1


func _can_break_poise(now: int) -> bool:
	if now < _next_poise_stun_allowed_ms:
		return false
	return _poise_hits_in_window >= poise_hits_required


func _enter_poise_stun(now: int) -> void:
	state = State.STUN
	_stun_until_ms = now + poise_stun_ms
	_poise_hits_in_window = 0
	_poise_window_start_ms = now
	_next_poise_stun_allowed_ms = now + poise_stun_cooldown_ms
	_is_fake_attack = false
	_feint_followup_attack = &""
	attack_area.deactivate()
	visual.speed_scale = 1.0
	visual.play(&"idle")
	TimeDirector.request_hit_stop(120, 0.08)
	TimeDirector.request_shake(140, 7.0)


func on_parried(player: Node2D, _hit_data: Dictionary) -> void:
	if state == State.DEAD:
		return
	attack_area.deactivate()
	var bonus: int = 42
	if state == State.BURST:
		bonus = 58
	hp = max(hp - bonus, 0)
	emit_hp_changed()
	TimeDirector.request_hit_stop(320, 0.04)
	TimeDirector.request_flash(Color(1.0, 0.98, 0.95, 0.95), 170, 0.42)
	_update_phase()
	if hp <= 0:
		_die()
		return
	state = State.STUN
	visual.speed_scale = 1.0
	visual.play(&"idle")
	_is_fake_attack = false
	_feint_followup_attack = &""
	_combo_step = 0
	velocity.x = signf(global_position.x - player.global_position.x) * 160.0
	_stun_until_ms = Time.get_ticks_msec() + 1250


func _physics_process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer = max(_flash_timer - delta, 0.0)
		visual.modulate = Color(1.0, 0.82, 0.82, 1.0)
	else:
		visual.modulate = Color.WHITE

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if not active or player_ref == null or state == State.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
		move_and_slide()
		_refresh_visual_alignment()
		queue_redraw()
		return

	var now := Time.get_ticks_msec()
	var distance_x: float = player_ref.global_position.x - global_position.x
	_update_facing(distance_x, now)
	visual.flip_h = facing < 0.0
	$AttackArea/CollisionShape2D.position.x = 96.0 * facing

	match state:
		State.STUN, State.HURT:
			velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
			if now >= _stun_until_ms:
				state = State.IDLE
				visual.speed_scale = 1.0
				visual.play(&"idle")
		State.FEINT:
			_process_feint(now, delta)
		State.JUMP:
			_process_jump(now, delta)
		State.SWEEP, State.SLAM, State.GRAB, State.BURST:
			if state == State.GRAB:
				velocity.x = move_toward(velocity.x, facing * 205.0, 1500.0 * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
		_:
			_process_idle_or_chase(now, distance_x, delta)

	move_and_slide()
	_refresh_visual_alignment()
	queue_redraw()


func _update_facing(distance_x: float, now: int) -> void:
	if absf(distance_x) <= turn_dead_zone:
		return
	var desired: float = signf(distance_x)
	if desired == 0.0:
		return
	if desired != facing and now >= _next_turn_allowed_ms:
		facing = desired
		_next_turn_allowed_ms = now + min_turn_interval_ms


func _process_idle_or_chase(now: int, distance_x: float, delta: float) -> void:
	var abs_distance := absf(distance_x)
	if now >= next_attack_ms and _can_open_attack(abs_distance):
		_start_attack(abs_distance, now)
		return
	if abs_distance <= detect_range:
		state = State.CHASE
		if visual.animation != &"chase":
			visual.play(&"chase")
		visual.speed_scale = 1.0 + clampf((abs_distance - 80.0) / 420.0, 0.0, 0.22)
		velocity.x = move_toward(velocity.x, signf(distance_x) * move_speed, 900.0 * delta)
	else:
		state = State.IDLE
		visual.speed_scale = 1.0
		if visual.animation != &"idle":
			visual.play(&"idle")
		velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)


func _can_open_attack(distance_to_player: float) -> bool:
	if distance_to_player <= attack_range + 20.0:
		return true
	if phase >= 2 and distance_to_player >= far_jump_trigger_distance and distance_to_player <= detect_range:
		return randf() <= far_jump_trigger_chance
	return false


func _start_attack(distance_to_player: float, now: int) -> void:
	var choice := _select_scored_attack(distance_to_player, now)
	if choice == &"":
		return
	if _should_use_feint(distance_to_player, choice, now):
		_start_feint(choice, now)
		return
	_execute_attack(choice, now)
	if choice == &"jump":
		return
	var recovery := _recovery_for_attack(choice)
	if _combo_step == 0:
		recovery += int(attack_cooldown_ms * 0.45)
	next_attack_ms = now + recovery


func _select_scored_attack(distance_to_player: float, now: int) -> StringName:
	if now > _combo_active_until_ms:
		_combo_step = 0
	var next_combo_step := _combo_step + 1
	if next_combo_step > 3:
		next_combo_step = 1

	var candidates: Array[StringName] = [&"sweep", &"slam", &"grab"]
	if phase >= 2:
		candidates.append(&"jump")
	if phase >= 3:
		candidates.append(&"burst")

	var dodge_age := _read_player_recent_dodge_age_ms(now)
	var best_attack: StringName = &""
	var best_score := -99999.0
	for attack_name in candidates:
		var score := _calculate_attack_score(attack_name, distance_to_player, dodge_age, now, next_combo_step)
		if score > best_score:
			best_score = score
			best_attack = attack_name

	_combo_step = next_combo_step
	_combo_active_until_ms = now + combo_link_window_ms
	return best_attack


func _calculate_attack_score(
	attack_name: StringName,
	distance_to_player: float,
	dodge_age_ms: int,
	now: int,
	combo_step: int
) -> float:
	var score := 0.0
	match attack_name:
		&"sweep":
			score = 2.4 - absf(distance_to_player - 110.0) / 75.0
		&"grab":
			score = 2.0 - absf(distance_to_player - 170.0) / 92.0
		&"slam":
			score = 1.8 - absf(distance_to_player - 150.0) / 105.0
		&"jump":
			score = 1.0 + clampf((distance_to_player - 220.0) / 110.0, -1.2, 2.8)
		&"burst":
			score = 1.3 + clampf((distance_to_player - 160.0) / 95.0, -1.1, 1.2)
		_:
			score = -20.0

	if phase == 1 and attack_name == &"jump":
		score -= 4.0
	if phase < 3 and attack_name == &"burst":
		score -= 9.0

	if dodge_age_ms < 560:
		if attack_name == &"grab":
			score += 1.4
		elif attack_name == &"slam":
			score += 0.9
		elif attack_name == &"sweep":
			score -= 0.55

	match combo_step:
		1:
			if attack_name == &"sweep":
				score += 0.85
		2:
			if attack_name in [&"grab", &"slam"]:
				score += 0.7
		3:
			if attack_name in [&"slam", &"burst"]:
				score += 0.95

	if attack_name == _last_attack_used:
		var since_last := now - _last_attack_used_ms
		if since_last < 900:
			score -= 2.4
		elif since_last < 1700:
			score -= 1.25

	if attack_name == &"jump" and distance_to_player < 180.0:
		score -= 2.6
	if attack_name == &"burst" and distance_to_player > 280.0:
		score -= 1.4

	score += randf_range(-0.18, 0.18)
	return score


func _read_player_recent_dodge_age_ms(now: int) -> int:
	if player_ref == null:
		return 9999
	var dodge_value: Variant = player_ref.get("dodge_started_ms")
	if typeof(dodge_value) in [TYPE_INT, TYPE_FLOAT]:
		var dodge_ms: int = int(dodge_value)
		if dodge_ms > 0:
			return maxi(0, now - dodge_ms)
	return 9999


func _should_use_feint(distance_to_player: float, choice: StringName, now: int) -> bool:
	if choice in [&"jump", &"burst"]:
		return false
	if distance_to_player > attack_range + 24.0:
		return false
	if now - _last_feint_ms < 1100:
		return false
	if state in [State.HURT, State.STUN, State.FEINT, State.JUMP]:
		return false
	return randf() <= feint_probability


func _start_feint(choice: StringName, now: int) -> void:
	state = State.FEINT
	_is_fake_attack = true
	_feint_followup_attack = choice
	_feint_release_ms = now + 260
	_last_feint_ms = now
	attack_area.deactivate()
	visual.speed_scale = 1.1
	visual.play(&"sweep")
	_play_attack_sfx(1.08)
	next_attack_ms = _feint_release_ms + 120


func _process_feint(now: int, delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1900.0 * delta)
	attack_area.deactivate()
	if now >= _feint_release_ms and _feint_followup_attack != &"":
		var followup := _feint_followup_attack
		_feint_followup_attack = &""
		_is_fake_attack = false
		_execute_attack(followup, now)
		if followup == &"jump":
			return
		var recovery := _recovery_for_attack(followup)
		if _combo_step == 0:
			recovery += int(attack_cooldown_ms * 0.4)
		next_attack_ms = now + recovery


func _execute_attack(choice: StringName, now: int) -> void:
	_last_attack_used = choice
	_last_attack_used_ms = now
	match choice:
		&"sweep":
			state = State.SWEEP
			visual.speed_scale = 1.18
			visual.play(&"sweep")
			_play_attack_sfx(1.12)
		&"slam":
			state = State.SLAM
			visual.speed_scale = 0.9
			visual.play(&"slam")
			_play_attack_sfx(0.88)
		&"jump":
			state = State.JUMP
			visual.speed_scale = 1.06
			_jump_started_ms = now
			_jump_origin_x = global_position.x
			var target_bias: float = 52.0 * signf(player_ref.global_position.x - global_position.x)
			_jump_target_x = player_ref.global_position.x - target_bias
			_jump_travel_duration_ms = jump_travel_ms + (160 if absf(_jump_target_x - _jump_origin_x) > 300.0 else 0)
			_jump_visual_lift = 0.0
			visual.play(&"jump")
			_play_attack_sfx(0.98)
		&"grab":
			state = State.GRAB
			visual.speed_scale = 0.84
			visual.play(&"grab")
			_play_attack_sfx(0.92)
		&"burst":
			state = State.BURST
			visual.speed_scale = 0.94
			_burst_flash_armed = true
			visual.play(&"burst")
			_play_burst_sfx(1.0)
			_spawn_fx(_burst_fx_frames, &"burst", global_position + Vector2(0.0, -62.0), Vector2(0.48, 0.48))


func _process_jump(now: int, delta: float) -> void:
	attack_area.deactivate()
	var elapsed := now - _jump_started_ms
	if elapsed < jump_takeoff_ms:
		velocity.x = move_toward(velocity.x, 0.0, 2100.0 * delta)
		var charge_t := clampf(float(elapsed) / float(maxi(jump_takeoff_ms, 1)), 0.0, 1.0)
		_jump_visual_lift = -18.0 * sin(charge_t * PI)
		return

	var travel_elapsed := elapsed - jump_takeoff_ms
	var progress := clampf(float(travel_elapsed) / float(maxi(_jump_travel_duration_ms, 1)), 0.0, 1.0)
	var eased := progress * progress * (3.0 - 2.0 * progress)
	global_position.x = lerpf(_jump_origin_x, _jump_target_x, eased)
	_jump_visual_lift = -sin(progress * PI) * jump_arc_height
	if progress >= 1.0:
		_jump_visual_lift = 0.0
		state = State.SLAM
		visual.speed_scale = 0.92
		visual.play(&"slam")
		_play_attack_sfx(0.84)
		_spawn_fx(_boom_frames, &"boom", global_position + Vector2(0.0, -18.0), Vector2(0.78, 0.78))
		TimeDirector.request_shake(280, 17.0)
		next_attack_ms = Time.get_ticks_msec() + slow_recovery_ms + 120


func _recovery_for_attack(attack_name: StringName) -> int:
	match attack_name:
		&"sweep":
			return fast_recovery_ms
		&"grab", &"slam", &"burst":
			return slow_recovery_ms
		&"jump":
			return slow_recovery_ms + 120
		_:
			return attack_cooldown_ms


func _die() -> void:
	state = State.DEAD
	active = false
	attack_area.deactivate()
	_burst_flash_armed = false
	visual.speed_scale = 1.0
	_jump_visual_lift = 0.0
	_clear_active_fx()
	visual.play(&"dead")
	_apply_visual_transform()
	TimeDirector.request_hit_stop(320, 0.05)
	TimeDirector.request_shake(520, 18.0)
	_spawn_fx(_boom_frames, &"boom", global_position + Vector2(-34.0, -18.0), Vector2(0.76, 0.76))
	_spawn_fx(_boom_frames, &"boom", global_position + Vector2(28.0, -14.0), Vector2(0.68, 0.68))
	EventBus.emit_game_event(&"boss.hp.zero")


func _update_phase() -> void:
	var ratio := float(hp) / float(max_hp)
	var new_phase := 1
	if ratio <= 0.25:
		new_phase = 3
	elif ratio <= 0.60:
		new_phase = 2
	if new_phase == phase:
		return
	phase = new_phase
	phase_changed.emit(phase)
	GameState.set_boss_phase(phase)
	EventBus.emit_game_event(&"boss.phase.enter", {"phase": phase}, "boss_phase_%d" % phase)
	TimeDirector.request_hit_stop(220, 0.06)
	TimeDirector.request_flash(Color(1.0, 0.22, 0.2, 0.85), 180, 0.26)


func _spawn_fx(frames: SpriteFrames, animation_name: StringName, spawn_position: Vector2, fx_scale: Vector2) -> AnimatedSprite2D:
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = frames
	fx.animation = animation_name
	fx.position = spawn_position
	fx.scale = fx_scale
	fx.z_index = 30
	get_parent().add_child(fx)
	_active_fx.append(fx)
	fx.play()
	fx.animation_finished.connect(func() -> void:
		_active_fx.erase(fx)
		fx.queue_free()
	)
	return fx


func _clear_active_fx() -> void:
	for fx in _active_fx:
		if is_instance_valid(fx):
			fx.queue_free()
	_active_fx.clear()


func _on_visual_frame_changed() -> void:
	_refresh_visual_alignment()
	if state == State.FEINT or _is_fake_attack:
		attack_area.deactivate()
		return
	match visual.animation:
		&"sweep":
			if visual.frame in [2, 3]:
				attack_area.arm({
					"owner_actor": self,
					"damage": 14 + phase * 2,
					"attack_name": &"boss_attack_sweep",
					"knockback": Vector2(250.0 * facing, -58.0),
					"can_be_parried": true
				})
			else:
				attack_area.deactivate()
		&"grab":
			if visual.frame in [3, 4]:
				attack_area.arm({
					"owner_actor": self,
					"damage": 18 + phase * 2,
					"attack_name": &"boss_attack_grab",
					"knockback": Vector2(300.0 * facing, -70.0),
					"can_be_parried": false,
					"is_grab": true
				})
			else:
				attack_area.deactivate()
		&"slam":
			if visual.frame in [9, 14, 17]:
				attack_area.arm({
					"owner_actor": self,
					"damage": 12 + phase * 2,
					"attack_name": &"boss_attack_slam",
					"knockback": Vector2(198.0 * facing, -90.0),
					"can_be_parried": true
				})
				_spawn_fx(_boom_frames, &"boom", global_position + Vector2(0.0, -12.0), Vector2(0.58, 0.58))
				TimeDirector.request_shake(170, 12.5)
			else:
				attack_area.deactivate()
		&"burst":
			if visual.frame in [4, 5]:
				attack_area.arm({
					"owner_actor": self,
					"damage": 16 + phase * 2,
					"attack_name": &"boss_attack_burst",
					"knockback": Vector2(228.0 * facing, -76.0),
					"can_be_parried": true
				})
				if _burst_flash_armed:
					_burst_flash_armed = false
					TimeDirector.request_flash(Color(1.0, 0.18, 0.16, 0.66), 90, 0.16)
			else:
				attack_area.deactivate()
		_:
			attack_area.deactivate()


func _on_visual_animation_finished() -> void:
	if visual.animation == &"burst":
		_burst_flash_armed = false
	if state == State.FEINT:
		return
	match visual.animation:
		&"sweep", &"grab", &"slam", &"burst":
			attack_area.deactivate()
			visual.speed_scale = 1.0
			if state != State.DEAD and state != State.JUMP:
				state = State.IDLE
				visual.play(&"idle")
		&"dead":
			defeated.emit()


func _on_attack_hit_target(_target: Node, _hit_data: Dictionary) -> void:
	TimeDirector.request_hit_stop(90, 0.08)
	TimeDirector.request_shake(120, 9.0)


func _draw() -> void:
	draw_circle(Vector2(0.0, 5.0), 42.0, Color(0.02, 0.02, 0.03, 0.42))
	var aura_alpha := 0.08 + phase * 0.03
	draw_arc(Vector2.ZERO, 86.0, -0.6, 0.6, 24, Color(1.0, 0.18, 0.16, aura_alpha), 3.0)
	draw_arc(Vector2.ZERO, 86.0, PI - 0.6, PI + 0.6, 24, Color(1.0, 0.18, 0.16, aura_alpha), 3.0)


func _play_attack_sfx(pitch: float = 1.0) -> void:
	if _attack_sfx_player.stream == null:
		return
	_attack_sfx_player.pitch_scale = pitch
	_attack_sfx_player.play()


func _play_burst_sfx(pitch: float = 1.0) -> void:
	if _burst_sfx_player.stream == null:
		return
	_burst_sfx_player.pitch_scale = pitch
	_burst_sfx_player.play()


func _load_first_stream(paths: Array) -> AudioStream:
	for path in paths:
		if ResourceLoader.exists(path):
			var stream := load(path)
			if stream is AudioStream:
				return stream
	return null

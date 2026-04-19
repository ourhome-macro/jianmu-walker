extends CharacterBody2D
class_name Player

const AnimationFactoryRef = preload("res://scripts/core/animation_factory.gd")
const ATTACK_SFX_CANDIDATES := [
	"res://assets/audio/主角武器挥舞.mp3",
	"res://assets/audio/player_attack.mp3"
]
const PARRY_SFX_CANDIDATES := [
	"res://assets/audio/弹反.mp3",
	"res://assets/audio/player_parry.mp3"
]

signal hp_changed(current_hp: int, max_hp: int)
signal hp_zero
signal perfect_dodge
signal perfect_parry
signal tutorial_action(action_name: StringName)
signal attack_hit(target: Node)

const GRAVITY := 2400.0

enum State {
	IDLE,
	MOVE,
	JUMP,
	FALL,
	ATTACK,
	DODGE,
	GUARD,
	PARRY,
	HURT,
	DEAD,
	LOCKED
}

@export var max_hp: int = 140
@export var move_speed: float = 245.0
@export var acceleration: float = 2100.0
@export var friction: float = 2600.0
@export var air_acceleration: float = 1600.0
@export var air_friction: float = 900.0
@export var jump_velocity: float = -860.0
@export var max_fall_speed: float = 1280.0
@export var dodge_speed: float = 560.0
@export var perfect_dodge_window_ms: int = 150
@export var perfect_parry_window_ms: int = 400
@export var invincible_ms_on_dodge: int = 220
@export var guard_chip_ratio: float = 0.18
@export_range(0.0, 1.0, 0.01) var perfect_dodge_heal_ratio: float = 0.10
@export_range(0.0, 1.0, 0.01) var perfect_parry_heal_ratio: float = 0.15
@export var attack_interval_ms: int = 420
@export var dodge_interval_ms: int = 620
@export var guard_interval_ms: int = 360
@export var attack_buffer_ms: int = 140

var hp: int = max_hp
var facing: float = 1.0
var state: State = State.LOCKED
var control_enabled: bool = false
var combo_step: int = 0
var queued_combo: bool = false
var last_attack_pressed_ms: int = -10_000
var last_attack_started_ms: int = -10_000
var dodge_started_ms: int = -10_000
var guard_pressed_ms: int = -10_000
var invincible_until_ms: int = 0
var next_attack_available_ms: int = 0
var next_dodge_available_ms: int = 0
var next_guard_available_ms: int = 0
var _air_dodge_available: bool = true
var _dodge_collision_exceptions: Array[PhysicsBody2D] = []
var no_damage_mode: bool = false
var _flash_timer: float = 0.0
var _afterimage_accumulator: float = 0.0

@onready var visual: AnimatedSprite2D = $Visual
@onready var attack_area: Area2D = $AttackArea
@onready var body_shape: CollisionShape2D = $BodyCollision
@onready var _attack_sfx_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
@onready var _parry_sfx_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()


func _ready() -> void:
	add_to_group("player")
	visual.sprite_frames = AnimationFactoryRef.build_player_frames()
	visual.play(&"idle")
	visual.frame_changed.connect(_on_visual_frame_changed)
	visual.animation_finished.connect(_on_visual_animation_finished)
	attack_area.hit_target.connect(_on_attack_hit_target)
	$Hurtbox.add_to_group("hurtbox")
	add_child(_attack_sfx_player)
	add_child(_parry_sfx_player)
	_attack_sfx_player.stream = _load_first_stream(ATTACK_SFX_CANDIDATES)
	_attack_sfx_player.volume_db = -1.6
	_parry_sfx_player.stream = _load_first_stream(PARRY_SFX_CANDIDATES)
	_parry_sfx_player.volume_db = -0.4
	emit_hp_changed()


func _physics_process(delta: float) -> void:
	var now := Time.get_ticks_msec()
	var was_on_floor := is_on_floor()
	if _flash_timer > 0.0:
		_flash_timer = max(_flash_timer - delta, 0.0)
		var t := clampf(_flash_timer / 0.18, 0.0, 1.0)
		var strength := 1.0 - (0.35 * t)
		visual.modulate = Color(1.0, strength, strength, 1.0)
	else:
		visual.modulate = Color.WHITE

	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, max_fall_speed)
	elif absf(velocity.y) < 4.0:
		velocity.y = 0.0

	if control_enabled:
		_handle_actions(now)

	if is_on_floor() and state != State.DODGE:
		_air_dodge_available = true

	match state:
		State.IDLE, State.MOVE, State.GUARD:
			_handle_ground_motion(delta)
		State.JUMP, State.FALL:
			_handle_air_motion(delta)
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta * 0.8)
		State.DODGE:
			_afterimage_accumulator += delta
			if _afterimage_accumulator >= 0.05:
				_afterimage_accumulator = 0.0
				_spawn_afterimage()
		State.HURT:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta * 0.3)
		State.PARRY:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		State.DEAD, State.LOCKED:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()
	_update_air_state(was_on_floor)
	_update_orientation()

	if is_on_floor():
		if state == State.IDLE and absf(velocity.x) > 2.0:
			_change_state(State.MOVE)
		elif state == State.MOVE and absf(velocity.x) <= 2.0:
			_change_state(State.IDLE)

	if state == State.GUARD and not Input.is_action_pressed(&"guard"):
		_exit_guard()


func enable_control() -> void:
	control_enabled = true
	if state == State.LOCKED:
		_change_state(State.IDLE)


func lock_for_cinematic() -> void:
	control_enabled = false
	attack_area.deactivate()
	_set_enemy_pass_through(false)
	velocity = Vector2.ZERO
	_change_state(State.LOCKED)
	if visual.animation != &"idle":
		visual.play(&"idle")


func emit_hp_changed() -> void:
	hp_changed.emit(hp, max_hp)


func _heal_by_ratio(ratio: float) -> void:
	if ratio <= 0.0 or hp >= max_hp:
		return
	var heal_amount := maxi(1, int(round(float(max_hp) * ratio)))
	hp = mini(max_hp, hp + heal_amount)
	emit_hp_changed()


func refill_hp() -> void:
	hp = max_hp
	emit_hp_changed()


func force_recover_for_flow(enable_no_damage: bool = false) -> void:
	hp = max_hp
	emit_hp_changed()
	no_damage_mode = enable_no_damage
	control_enabled = true
	attack_area.deactivate()
	velocity = Vector2.ZERO
	combo_step = 0
	queued_combo = false
	last_attack_pressed_ms = -10_000
	last_attack_started_ms = -10_000
	next_attack_available_ms = 0
	next_dodge_available_ms = 0
	next_guard_available_ms = 0
	_air_dodge_available = true
	invincible_until_ms = 0
	_flash_timer = 0.0
	_set_enemy_pass_through(false)
	_change_state(State.IDLE)
	visual.play(&"idle")


func set_no_damage_mode(enabled: bool) -> void:
	no_damage_mode = enabled


func receive_hit(hit_data: Dictionary) -> void:
	if state == State.DEAD:
		return
	var now := Time.get_ticks_msec()
	if now < invincible_until_ms:
		if state == State.DODGE and now - dodge_started_ms <= perfect_dodge_window_ms:
			_trigger_perfect_dodge()
		return

	if state == State.GUARD:
		var guard_age := now - guard_pressed_ms
		if hit_data.get("can_be_parried", true) and guard_age <= perfect_parry_window_ms:
			_trigger_perfect_parry(hit_data)
			return
		_apply_guard_chip(hit_data)
		return

	var knockback := hit_data.get("knockback", Vector2.ZERO) as Vector2
	_take_damage(hit_data.get("damage", 10), knockback)


func _handle_actions(now: int) -> void:
	if state in [State.HURT, State.PARRY, State.DEAD, State.LOCKED]:
		return

	if is_on_floor() and state in [State.IDLE, State.MOVE, State.GUARD] and Input.is_action_just_pressed(&"jump"):
		_start_jump()
		return

	if is_on_floor() and Input.is_action_just_pressed(&"attack"):
		last_attack_pressed_ms = now
		if state == State.ATTACK:
			queued_combo = true
		elif state != State.DODGE and now >= next_attack_available_ms:
			_start_attack()

	if state in [State.IDLE, State.MOVE, State.GUARD, State.JUMP, State.FALL]:
		if Input.is_action_just_pressed(&"dodge") and now >= next_dodge_available_ms and (is_on_floor() or _air_dodge_available):
			_start_dodge()
			return

	if is_on_floor() and Input.is_action_just_pressed(&"guard") and state not in [State.ATTACK, State.DODGE] and now >= next_guard_available_ms:
		tutorial_action.emit(&"guard")
		guard_pressed_ms = now
		_enter_guard()


func _handle_ground_motion(delta: float) -> void:
	if state == State.GUARD:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		return
	var input_axis := _get_move_axis()
	if absf(input_axis) > 0.1:
		facing = sign(input_axis)
		velocity.x = move_toward(velocity.x, input_axis * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _handle_air_motion(delta: float) -> void:
	var input_axis := _get_move_axis()
	if absf(input_axis) > 0.1:
		facing = sign(input_axis)
		velocity.x = move_toward(velocity.x, input_axis * move_speed * 0.9, air_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, air_friction * delta)


func _start_attack(_force_chain: bool = false) -> bool:
	var now := Time.get_ticks_msec()
	if now < next_attack_available_ms:
		return false
	next_attack_available_ms = now + attack_interval_ms
	tutorial_action.emit(&"attack")
	if _attack_sfx_player.stream != null:
		_attack_sfx_player.play()
	if now - last_attack_started_ms > 480:
		combo_step = 0
	combo_step = clamp(combo_step + 1, 1, 3)
	last_attack_started_ms = now
	queued_combo = false
	_change_state(State.ATTACK)
	match combo_step:
		1:
			visual.play(&"attack_1")
		2:
			visual.play(&"attack_2")
		3:
			visual.play(&"attack_3")
	attack_area.deactivate()
	velocity.x = facing * (64.0 + combo_step * 14.0)
	return true


func _start_dodge() -> void:
	var now := Time.get_ticks_msec()
	if now < next_dodge_available_ms:
		return
	next_dodge_available_ms = now + dodge_interval_ms
	if not is_on_floor():
		_air_dodge_available = false
	tutorial_action.emit(&"dodge")
	_change_state(State.DODGE)
	dodge_started_ms = now
	invincible_until_ms = dodge_started_ms + invincible_ms_on_dodge
	_set_enemy_pass_through(true)
	_afterimage_accumulator = 0.0
	velocity.x = facing * dodge_speed
	visual.play(&"dodge")
	TimeDirector.request_flash(Color(0.2, 0.62, 1.0, 0.8), 80, 0.16)


func _start_jump() -> void:
	_change_state(State.JUMP)
	velocity.y = jump_velocity
	visual.play(&"jump_start")


func _enter_guard() -> void:
	next_guard_available_ms = Time.get_ticks_msec() + guard_interval_ms
	_change_state(State.GUARD)
	visual.play(&"guard_raise")


func _exit_guard() -> void:
	if state != State.GUARD:
		return
	_change_state(State.IDLE)
	visual.play(&"idle")


func _take_damage(amount: int, knockback: Vector2) -> void:
	if no_damage_mode:
		_flash_timer = 0.12
		TimeDirector.request_flash(Color(0.82, 0.92, 1.0, 0.28), 70, 0.08)
		_change_state(State.HURT)
		visual.play(&"hurt")
		velocity = knockback * 0.35
		return
	hp = max(hp - amount, 0)
	emit_hp_changed()
	_flash_timer = 0.18
	TimeDirector.request_flash(Color(1.0, 0.22, 0.22, 0.75), 90, 0.28)
	TimeDirector.request_shake(120, 9.0)
	if hp <= 0:
		_die()
		return
	_change_state(State.HURT)
	visual.play(&"hurt")
	velocity = knockback


func _apply_guard_chip(hit_data: Dictionary) -> void:
	if no_damage_mode:
		TimeDirector.request_shake(50, 4.0)
		velocity.x = -facing * 40.0
		return
	var chip := maxi(1, int(round(hit_data.get("damage", 10) * guard_chip_ratio)))
	hp = max(hp - chip, 0)
	emit_hp_changed()
	visual.modulate = Color(0.75, 0.92, 1.0, 1.0)
	TimeDirector.request_shake(90, 6.0)
	velocity.x = -facing * 90.0
	if hp <= 0:
		_die()


func _trigger_perfect_dodge() -> void:
	invincible_until_ms = Time.get_ticks_msec() + 550
	_heal_by_ratio(perfect_dodge_heal_ratio)
	perfect_dodge.emit()
	EventBus.emit_game_event(&"player.dodge.perfect")
	TimeDirector.request_hit_stop(260, 0.05)
	TimeDirector.request_flash(Color(0.24, 0.82, 1.0, 0.8), 180, 0.24)
	TimeDirector.request_shake(180, 10.0)


func _trigger_perfect_parry(hit_data: Dictionary) -> void:
	if _parry_sfx_player.stream != null:
		_parry_sfx_player.play()
	invincible_until_ms = Time.get_ticks_msec() + 400
	_heal_by_ratio(perfect_parry_heal_ratio)
	perfect_parry.emit()
	EventBus.emit_game_event(&"player.parry.perfect")
	_change_state(State.PARRY)
	visual.play(&"parry")
	velocity.x = -facing * 60.0
	TimeDirector.request_hit_stop(280, 0.04)
	TimeDirector.request_flash(Color(0.95, 0.98, 1.0, 0.95), 160, 0.38)
	TimeDirector.request_shake(220, 13.0)
	var source := hit_data.get("source_actor") as Node
	if source != null and source.has_method("on_parried"):
		source.on_parried(self, hit_data)


func _die() -> void:
	control_enabled = false
	attack_area.deactivate()
	_set_enemy_pass_through(false)
	_change_state(State.DEAD)
	visual.play(&"dead")
	hp_zero.emit()
	EventBus.emit_game_event(&"player.hp.zero")


func _change_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	match state:
		State.IDLE:
			if visual.animation != &"idle":
				visual.play(&"idle")
		State.MOVE:
			if visual.animation != &"move":
				visual.play(&"move")
		State.GUARD:
			if visual.animation not in [&"guard_raise", &"guard_hold"]:
				visual.play(&"guard_hold")
		_:
			pass


func _update_air_state(was_on_floor: bool) -> void:
	if state in [State.DEAD, State.LOCKED]:
		return
	if is_on_floor():
		if not was_on_floor and state in [State.JUMP, State.FALL]:
			if absf(velocity.x) > 2.0:
				_change_state(State.MOVE)
				visual.play(&"move")
			else:
				_change_state(State.IDLE)
				visual.play(&"idle")
		return
	if state in [State.IDLE, State.MOVE, State.JUMP, State.FALL]:
		if velocity.y < 0.0:
			if state != State.JUMP:
				_change_state(State.JUMP)
			if visual.animation != &"jump_rise" and visual.animation != &"jump_start":
				visual.play(&"jump_rise")
		else:
			if state != State.FALL:
				_change_state(State.FALL)
			if visual.animation != &"jump_fall":
				visual.play(&"jump_fall")


func _update_orientation() -> void:
	visual.flip_h = facing < 0.0
	var attack_position := Vector2(44.0 * facing, -28.0)
	$AttackArea/CollisionShape2D.position = attack_position
	body_shape.position.x = 0.0


func _on_visual_frame_changed() -> void:
	match visual.animation:
		&"attack_1":
			_update_attack_window(visual.frame, 14, Vector2(180.0 * facing, -40.0), &"player_attack_1", [1, 2])
		&"attack_2":
			_update_attack_window(visual.frame, 18, Vector2(220.0 * facing, -55.0), &"player_attack_2", [1, 2, 3])
		&"attack_3":
			_update_attack_window(visual.frame, 24, Vector2(280.0 * facing, -70.0), &"player_attack_3", [1, 2, 3])
		&"parry":
			if visual.frame in [4, 5]:
				_spawn_parry_arc()
		_:
			attack_area.deactivate()


func _on_visual_animation_finished() -> void:
	match visual.animation:
		&"attack_1", &"attack_2":
			attack_area.deactivate()
			var buffered_input := Time.get_ticks_msec() - last_attack_pressed_ms <= attack_buffer_ms
			if queued_combo or buffered_input:
				var chained := _start_attack(true)
				if not chained:
					queued_combo = false
					_change_state(State.IDLE)
					visual.play(&"idle")
			else:
				_change_state(State.IDLE)
				visual.play(&"idle")
		&"attack_3":
			attack_area.deactivate()
			combo_step = 0
			last_attack_started_ms = -10_000
			if queued_combo:
				queued_combo = false
			_change_state(State.IDLE)
			visual.play(&"idle")
		&"dodge":
			_set_enemy_pass_through(false)
			if is_on_floor():
				_change_state(State.IDLE)
				visual.play(&"idle")
			else:
				_change_state(State.FALL)
				visual.play(&"jump_fall")
		&"guard_raise":
			if state == State.GUARD and Input.is_action_pressed(&"guard"):
				visual.play(&"guard_hold")
			else:
				_exit_guard()
		&"jump_start":
			if not is_on_floor():
				if velocity.y < 0.0:
					visual.play(&"jump_rise")
				else:
					_change_state(State.FALL)
					visual.play(&"jump_fall")
		&"parry":
			if Input.is_action_pressed(&"guard"):
				_change_state(State.GUARD)
				visual.play(&"guard_hold")
			else:
				_change_state(State.IDLE)
				visual.play(&"idle")
		&"hurt":
			if state != State.DEAD:
				if is_on_floor():
					_change_state(State.IDLE)
					visual.play(&"idle")
				else:
					_change_state(State.FALL)
					visual.play(&"jump_fall")


func _update_attack_window(frame: int, damage_amount: int, knockback: Vector2, attack_name: StringName, active_frames: Array) -> void:
	if active_frames.has(frame):
		attack_area.arm({
			"owner_actor": self,
			"damage": damage_amount,
			"attack_name": attack_name,
			"knockback": knockback,
			"can_be_parried": false
		})
	else:
		attack_area.deactivate()


func _on_attack_hit_target(target: Node, _hit_data: Dictionary) -> void:
	attack_hit.emit(target)
	EventBus.emit_game_event(&"player.attack.hit")
	TimeDirector.request_hit_stop(45, 0.16)
	TimeDirector.request_shake(100, 7.0)


func _spawn_afterimage() -> void:
	var image := Sprite2D.new()
	image.texture = visual.sprite_frames.get_frame_texture(visual.animation, visual.frame)
	image.flip_h = visual.flip_h
	image.position = global_position + visual.position
	image.modulate = Color(0.3, 0.82, 1.0, 0.28)
	get_parent().add_child(image)
	var tween := create_tween()
	tween.tween_property(image, "modulate:a", 0.0, 0.18)
	tween.parallel().tween_property(image, "scale", Vector2(1.12, 1.12), 0.18)
	tween.finished.connect(image.queue_free)


func _spawn_parry_arc() -> void:
	var arc := Line2D.new()
	arc.width = 6.0
	arc.default_color = Color(0.9, 1.0, 1.0, 0.9)
	arc.position = global_position + Vector2(0.0, -34.0)
	var dir := facing
	arc.points = PackedVector2Array([
		Vector2(-8.0 * dir, -18.0),
		Vector2(18.0 * dir, -2.0),
		Vector2(46.0 * dir, 18.0)
	])
	get_parent().add_child(arc)
	var tween := create_tween()
	tween.tween_property(arc, "modulate:a", 0.0, 0.18)
	tween.parallel().tween_property(arc, "scale", Vector2(1.35, 1.35), 0.18)
	tween.finished.connect(arc.queue_free)


func _set_enemy_pass_through(enabled: bool) -> void:
	if enabled:
		_clear_dodge_collision_exceptions()
		for node in get_tree().get_nodes_in_group("enemy_actor"):
			var body := node as PhysicsBody2D
			if body == null or body == self:
				continue
			add_collision_exception_with(body)
			_dodge_collision_exceptions.append(body)
	else:
		_clear_dodge_collision_exceptions()
		_resolve_post_dodge_overlap()


func _clear_dodge_collision_exceptions() -> void:
	for body in _dodge_collision_exceptions:
		if is_instance_valid(body):
			remove_collision_exception_with(body)
	_dodge_collision_exceptions.clear()


func _resolve_post_dodge_overlap() -> void:
	var player_half := _get_shape_half_width(body_shape)
	if player_half <= 0.0:
		player_half = 12.0
	for node in get_tree().get_nodes_in_group("enemy_actor"):
		var enemy_body := node as CharacterBody2D
		if enemy_body == null:
			continue
		var enemy_shape := enemy_body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if enemy_shape == null:
			continue
		var enemy_half := _get_shape_half_width(enemy_shape)
		if enemy_half <= 0.0:
			enemy_half = 20.0
		if absf(global_position.y - enemy_body.global_position.y) > 96.0:
			continue
		var required_gap := player_half + enemy_half + 4.0
		var dx := global_position.x - enemy_body.global_position.x
		if absf(dx) >= required_gap:
			continue
		var push_dir: float = signf(dx)
		if absf(push_dir) <= 0.01:
			push_dir = facing
		global_position.x = enemy_body.global_position.x + push_dir * required_gap


func _get_shape_half_width(shape_node: CollisionShape2D) -> float:
	if shape_node == null or shape_node.shape == null:
		return 0.0
	if shape_node.shape is RectangleShape2D:
		return (shape_node.shape as RectangleShape2D).size.x * 0.5 * absf(shape_node.scale.x)
	if shape_node.shape is CircleShape2D:
		return (shape_node.shape as CircleShape2D).radius * absf(shape_node.scale.x)
	if shape_node.shape is CapsuleShape2D:
		var capsule := shape_node.shape as CapsuleShape2D
		return capsule.radius * absf(shape_node.scale.x)
	return 0.0


func _get_move_axis() -> float:
	var action_axis := Input.get_axis(&"move_left", &"move_right")
	if absf(action_axis) > 0.01:
		return action_axis
	return Input.get_axis(&"ui_left", &"ui_right")


func _load_first_stream(paths: Array) -> AudioStream:
	for path in paths:
		if ResourceLoader.exists(path):
			var stream := load(path)
			if stream is AudioStream:
				return stream
	return null

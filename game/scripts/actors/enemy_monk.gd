extends CharacterBody2D

const AnimationFactoryRef = preload("res://scripts/core/animation_factory.gd")
const ENEMY_WARNING_SFX_CANDIDATES := [
	"res://assets/audio/boss atk.mp3",
	"res://assets/audio/player_attack.mp3"
]

signal hp_changed(current_hp: int, max_hp: int)
signal defeated

const GRAVITY := 2400.0

enum State {
	IDLE,
	CHASE,
	ATTACK,
	HURT,
	DEAD
}

@export var max_hp: int = 80
@export var move_speed: float = 86.0
@export var detect_range: float = 420.0
@export var attack_range: float = 86.0
@export var attack_cooldown_ms: int = 1500
@export var hurt_stun_ms: int = 360
@export var visual_scale: float = 1.16
@export var visual_foot_y: float = 16.0
@export var hp_bar_y: float = -102.0
@export var attack_warning_ms: int = 300
@export var attack_warning_font_size: int = 54
@export var attack_warning_offset_y: float = -120.0

var hp: int = max_hp
var facing: float = -1.0
var player_ref: Node = null
var state: State = State.IDLE
var active: bool = false
var next_attack_ms: int = 0
var _hurt_recover_ms: int = 0
var _use_alt_attack: bool = false
var _flash_timer: float = 0.0
var _attack_warning_until_ms: int = 0

@onready var visual: AnimatedSprite2D = $Visual
@onready var attack_area: Area2D = $AttackArea
@onready var _warning_sfx_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()


func _ready() -> void:
	add_to_group("enemy_actor")
	visual.sprite_frames = AnimationFactoryRef.build_enemy_frames()
	_apply_visual_scale()
	visual.play(&"idle")
	visual.frame_changed.connect(_on_visual_frame_changed)
	visual.animation_finished.connect(_on_visual_animation_finished)
	attack_area.hit_target.connect(_on_attack_hit_target)
	$Hurtbox.add_to_group("hurtbox")
	add_child(_warning_sfx_player)
	_warning_sfx_player.stream = _load_first_stream(ENEMY_WARNING_SFX_CANDIDATES)
	_warning_sfx_player.volume_db = -6.0
	emit_hp_changed()


func _apply_visual_scale() -> void:
	visual.scale = Vector2.ONE * visual_scale
	visual.position.y = visual_foot_y - (64.0 * visual_scale)


func activate(player: Node) -> void:
	player_ref = player
	active = true
	state = State.IDLE
	visual.play(&"idle")


func _physics_process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer = max(_flash_timer - delta, 0.0)
		visual.modulate = Color(1.0, 0.72, 0.72, 1.0)
	else:
		visual.modulate = Color.WHITE

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if not active or player_ref == null or state == State.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
		move_and_slide()
		queue_redraw()
		return

	var now := Time.get_ticks_msec()
	var distance_x: float = player_ref.global_position.x - global_position.x
	facing = sign(distance_x) if absf(distance_x) > 2.0 else facing
	visual.flip_h = facing < 0.0
	$AttackArea/CollisionShape2D.position.x = 46.0 * facing

	if state == State.HURT:
		if now >= _hurt_recover_ms:
			state = State.IDLE
			visual.play(&"idle")
		velocity.x = move_toward(velocity.x, 0.0, 1700.0 * delta)
	elif state == State.ATTACK:
		if visual.animation == &"attack_2":
			velocity.x = move_toward(velocity.x, facing * 120.0, 900.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 1700.0 * delta)
	else:
		var abs_distance := absf(distance_x)
		if abs_distance <= attack_range and now >= next_attack_ms:
			_start_attack()
		elif abs_distance <= detect_range:
			state = State.CHASE
			visual.play(&"walk")
			velocity.x = move_toward(velocity.x, sign(distance_x) * move_speed, 1200.0 * delta)
		else:
			state = State.IDLE
			visual.play(&"idle")
			velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)

	move_and_slide()
	queue_redraw()


func receive_hit(hit_data: Dictionary) -> void:
	if state == State.DEAD:
		return
	hp = max(hp - hit_data.get("damage", 12), 0)
	emit_hp_changed()
	_flash_timer = 0.18
	if hp <= 0:
		_die()
		return
	state = State.HURT
	visual.play(&"idle")
	velocity = Vector2(sign(global_position.x - hit_data.get("source_position", global_position).x) * 150.0, -80.0)
	_hurt_recover_ms = Time.get_ticks_msec() + hurt_stun_ms


func on_parried(_player: Node, _hit_data: Dictionary) -> void:
	if state == State.DEAD:
		return
	attack_area.deactivate()
	hp = max(hp - 28, 0)
	emit_hp_changed()
	_flash_timer = 0.3
	TimeDirector.request_flash(Color(0.95, 0.98, 1.0, 0.9), 150, 0.34)
	if hp <= 0:
		_die()
		return
	state = State.HURT
	velocity = Vector2(sign(global_position.x - _player.global_position.x) * 220.0, -120.0)
	_hurt_recover_ms = Time.get_ticks_msec() + 720


func emit_hp_changed() -> void:
	hp_changed.emit(hp, max_hp)


func _start_attack() -> void:
	state = State.ATTACK
	_use_alt_attack = not _use_alt_attack
	_show_attack_warning(attack_warning_ms)
	visual.play(&"attack_2" if _use_alt_attack else &"attack_1")
	next_attack_ms = Time.get_ticks_msec() + attack_cooldown_ms


func _die() -> void:
	state = State.DEAD
	active = false
	attack_area.deactivate()
	visual.play(&"dead")
	EventBus.emit_game_event(&"enemy.hp.zero")


func _on_visual_frame_changed() -> void:
	match visual.animation:
		&"attack_1":
			if visual.frame in [1, 2]:
				attack_area.arm({
					"owner_actor": self,
					"damage": 12,
					"attack_name": &"enemy_attack_1",
					"knockback": Vector2(160.0 * facing, -35.0),
					"can_be_parried": true,
					"max_hit_distance": 130.0
				})
			else:
				attack_area.deactivate()
		&"attack_2":
			if visual.frame in [1, 2]:
				attack_area.arm({
					"owner_actor": self,
					"damage": 14,
					"attack_name": &"enemy_attack_2",
					"knockback": Vector2(210.0 * facing, -48.0),
					"can_be_parried": true,
					"max_hit_distance": 150.0
				})
			else:
				attack_area.deactivate()
		_:
			attack_area.deactivate()


func _on_visual_animation_finished() -> void:
	match visual.animation:
		&"attack_1", &"attack_2":
			if state != State.DEAD:
				state = State.IDLE
				visual.play(&"idle")
		&"dead":
			defeated.emit()


func _on_attack_hit_target(_target: Node, _hit_data: Dictionary) -> void:
	TimeDirector.request_hit_stop(70, 0.1)


func _draw() -> void:
	draw_circle(Vector2(0.0, 4.0), 18.0, Color(0.02, 0.02, 0.03, 0.35))
	if state != State.DEAD:
		var ratio := float(hp) / float(max_hp)
		draw_rect(Rect2(-24.0, hp_bar_y, 48.0, 6.0), Color(0.08, 0.08, 0.1, 0.55), true)
		draw_rect(Rect2(-24.0, hp_bar_y, 48.0 * ratio, 6.0), Color(0.86, 0.26, 0.3, 0.9), true)
	if state != State.DEAD and Time.get_ticks_msec() < _attack_warning_until_ms:
		_draw_attack_warning()


func _show_attack_warning(duration_ms: int) -> void:
	var expires_at := Time.get_ticks_msec() + duration_ms
	if expires_at > _attack_warning_until_ms:
		_attack_warning_until_ms = expires_at
		if _warning_sfx_player.stream != null:
			_warning_sfx_player.pitch_scale = 1.3
			_warning_sfx_player.play()


func _draw_attack_warning() -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var font_size := maxi(attack_warning_font_size, 16)
	var glyph_size := font.get_string_size("!", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var origin := Vector2(-glyph_size.x * 0.5, attack_warning_offset_y)
	var outline_color := Color(0.05, 0.03, 0.02, 0.92)
	draw_string(font, origin + Vector2(-2.0, 0.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_color)
	draw_string(font, origin + Vector2(2.0, 0.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_color)
	draw_string(font, origin + Vector2(0.0, -2.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_color)
	draw_string(font, origin + Vector2(0.0, 2.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_color)
	draw_string(font, origin, "!", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.92, 0.22, 1.0))


func _load_first_stream(paths: Array) -> AudioStream:
	for path in paths:
		if ResourceLoader.exists(path):
			var stream := load(path)
			if stream is AudioStream:
				return stream
	return null

extends Node2D

const ENEMY_SCENE = preload("res://scenes/actors/enemy/enemy_monk.tscn")
const BOSS_SCENE = preload("res://scenes/actors/boss/boss_kreiz.tscn")
const TRAINING_STRIKE_SCENE = preload("res://scenes/flow/training_strike.tscn")

const TUTORIAL_STAGE := &"tutorial"
const ENEMY_STAGE := &"enemy"
const BOSS_STAGE := &"boss"
const COLLAPSE_STAGE := &"collapse"
const ENDING_STAGE := &"ending"
const MAX_TUTORIAL_TRIAL_ATTEMPTS := 4

const STAGE_ZONE_WIDTH := 1920.0
const CAMERA_EDGE_MARGIN := 56.0
const TUTORIAL_ZONE := Vector2(0.0, STAGE_ZONE_WIDTH)
const ENEMY_ZONE := Vector2(STAGE_ZONE_WIDTH, STAGE_ZONE_WIDTH * 2.0)
const BOSS_ZONE := Vector2(STAGE_ZONE_WIDTH * 2.0, STAGE_ZONE_WIDTH * 3.0)

const NORMAL_BGM_CANDIDATES := [
	"res://assets/audio/music2.mp3",
	"res://assets/audio/music2.ogg",
	"res://assets/bgm/bgm2.mp3",
	"res://assets/bgm/bgm2.ogg",
	"res://assets/bgm/music2.mp3",
	"res://assets/bgm/music2.ogg"
]

const BOSS_BGM_CANDIDATES := [
	"res://assets/audio/music1.mp3",
	"res://assets/audio/music1.ogg",
	"res://assets/bgm/bgm1.mp3",
	"res://assets/bgm/bgm1.ogg",
	"res://assets/bgm/music1.mp3",
	"res://assets/bgm/music1.ogg"
]
const GROUND_Y := 596.0

var tutorial_keys: Array[StringName] = [&"attack", &"dodge", &"guard", &"perfect_dodge", &"perfect_parry"]
var tutorial_done: Dictionary = {
	&"attack": false,
	&"dodge": false,
	&"guard": false,
	&"perfect_dodge": false,
	&"perfect_parry": false
}

var enemy_ref: Node = null
var boss_ref: Node = null
var _tutorial_trials_started: bool = false
var _enemy_sequence_started: bool = false
var _boss_sequence_started: bool = false
var _collapse_running: bool = false
var _stage_transition_running: bool = false
var _menu_open: bool = false
var _portal_transition_requested: bool = false
var _current_zone: Vector2 = TUTORIAL_ZONE
var _current_stage_label: String = ""
var _normal_bgm: AudioStream = null
var _boss_bgm: AudioStream = null
var _bgm_tween: Tween = null

@onready var backdrop: Control = $BackdropLayer/Backdrop
@onready var player: Player = $Arena/Actors/Player
@onready var bot: Node2D = $Arena/Actors/JianmuBot
@onready var hud: CanvasLayer = $HUD
@onready var fx_root: Node2D = $Arena/FxRoot
@onready var camera: Camera2D = $CameraRig/Camera2D
@onready var tutorial_spawn: Marker2D = $Arena/SpawnPoints/TutorialSpawn
@onready var enemy_entry_spawn: Marker2D = $Arena/SpawnPoints/EnemyEntrySpawn
@onready var enemy_fight_spawn: Marker2D = $Arena/SpawnPoints/EnemyFightSpawn
@onready var boss_entry_spawn: Marker2D = $Arena/SpawnPoints/BossEntrySpawn
@onready var boss_fight_spawn: Marker2D = $Arena/SpawnPoints/BossFightSpawn
@onready var enemy_portal = $Arena/Portals/EnemyPortal
@onready var boss_portal = $Arena/Portals/BossPortal
@onready var bgm_player: AudioStreamPlayer = $BgmPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_map()
	_load_bgm_tracks()
	GameState.reset_demo()
	EventBus.clear_once_flags()

	player.global_position = tutorial_spawn.global_position
	player.lock_for_cinematic()
	player.hp_changed.connect(hud.set_player_hp)
	player.guard_posture_changed.connect(hud.set_guard_posture)
	player.tutorial_action.connect(_on_player_tutorial_action)
	player.perfect_dodge.connect(_on_player_perfect_dodge)
	player.perfect_parry.connect(_on_player_perfect_parry)
	player.hp_zero.connect(_on_player_dead)
	hud.set_player_hp(player.hp, player.max_hp)
	hud.set_guard_posture(player.guard_posture, player.guard_posture_max)
	hud.hide_boss_bar()
	hud.set_game_title("建木行者", "Jianmu Walker")

	enemy_portal.triggered.connect(_on_portal_triggered)
	boss_portal.triggered.connect(_on_portal_triggered)
	enemy_portal.set_active(false)
	boss_portal.set_active(false)

	bot.follow_target = player
	TimeDirector.flash_requested.connect(hud.flash)
	_set_zone(TUTORIAL_ZONE)
	_start_tutorial()
	call_deferred("_run_demo")


func _process(delta: float) -> void:
	var target_x := _get_camera_target_x(player.global_position.x)
	var target_position := Vector2(
		lerpf(
			camera.global_position.x,
			target_x,
			clamp(delta * 3.0, 0.0, 1.0)
		),
		360.0
	)
	camera.global_position = target_position
	camera.offset = _clamp_camera_offset(TimeDirector.camera_offset, target_position.x)
	_check_portal_proximity_fallback()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause_menu"):
		if _menu_open:
			_close_exit_menu()
		else:
			_open_exit_menu()
		get_viewport().set_input_as_handled()
		return
	if _menu_open and event.is_action_pressed(&"confirm"):
		get_tree().quit()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"confirm") and GameState.current_stage == ENDING_STAGE:
		get_tree().reload_current_scene()
		get_viewport().set_input_as_handled()


func _run_demo() -> void:
	_play_stage_bgm(_normal_bgm, 0.0)
	await hud.fade_from_black(0.55)
	await hud.show_title("建木行者", "链接数据世界", 1.5)
	call_deferred("_play_tutorial_intro_dialogue")


func _start_tutorial() -> void:
	GameState.set_stage(TUTORIAL_STAGE)
	backdrop.set_stage(TUTORIAL_STAGE)
	player.refill_hp()
	player.set_no_damage_mode(true)
	_set_stage_label("数据白域 · 适应场")
	hud.set_checklist([
		"完成一次普通攻击",
		"完成一次闪避",
		"完成一次格挡",
		"完成一次完美闪避",
		"完成一次完美弹反"
	])
	hud.show_prompt("A / D 移动   Space 跳跃   J 攻击   K 闪避   L 格挡", 4.2)


func _play_tutorial_intro_dialogue() -> void:
	await get_tree().create_timer(0.25, true, false, true).timeout
	await hud.say("建木机器人", "你已经成功链接上数据世界了，这里是为你准备的适应场所。", 2.3)
	await hud.say("建木机器人", "建梦的功能相当强大，甚至可以最大程度的还原一些战斗，你准备好了吗？", 2.2)
	await hud.say("主角", "为啥我的身体如此Q版", 1.8)
	await hud.say("建木机器人", "为了节省算力", 1.6)
	player.enable_control()
func _on_player_tutorial_action(action_name: StringName) -> void:
	if GameState.current_stage != TUTORIAL_STAGE:
		return
	if tutorial_done.has(action_name) and not tutorial_done[action_name]:
		_mark_tutorial(action_name)
	if _basic_tutorial_done() and not _tutorial_trials_started:
		_tutorial_trials_started = true
		call_deferred("_run_tutorial_trials")


func _on_player_perfect_dodge() -> void:
	if GameState.current_stage == TUTORIAL_STAGE and not tutorial_done[&"perfect_dodge"]:
		_mark_tutorial(&"perfect_dodge")


func _on_player_perfect_parry() -> void:
	if GameState.current_stage == TUTORIAL_STAGE and not tutorial_done[&"perfect_parry"]:
		_mark_tutorial(&"perfect_parry")


func _run_tutorial_trials() -> void:
	player.refill_hp()
	player.set_no_damage_mode(true)
	var dodge_attempts := 0
	while not tutorial_done[&"perfect_dodge"] and dodge_attempts < MAX_TUTORIAL_TRIAL_ATTEMPTS:
		dodge_attempts += 1
		hud.show_prompt("完美闪避：红线划过你身前的一瞬间翻滚", 1.8)
		await _spawn_training_strike(&"dodge")
		await get_tree().create_timer(0.45, true, false, true).timeout
	if not tutorial_done[&"perfect_dodge"]:
		hud.show_prompt("完美闪避未触发，训练已允许跳过。", 1.8)
		await get_tree().create_timer(0.55, true, false, true).timeout
	var parry_attempts := 0
	while not tutorial_done[&"perfect_parry"] and parry_attempts < MAX_TUTORIAL_TRIAL_ATTEMPTS:
		parry_attempts += 1
		hud.show_prompt("完美弹反：斩击落下前按下格挡", 1.8)
		await _spawn_training_strike(&"parry")
		await get_tree().create_timer(0.45, true, false, true).timeout
	if not tutorial_done[&"perfect_parry"]:
		hud.show_prompt("完美弹反未触发，训练已允许跳过。", 1.8)
		await get_tree().create_timer(0.55, true, false, true).timeout
	await hud.say("建木机器人", "你的反应能力相当了不起。", 2.5)
	_unlock_portal(enemy_portal, "废土残片")


func _spawn_training_strike(mode: StringName) -> void:
	var strike := TRAINING_STRIKE_SCENE.instantiate()
	strike.global_position = player.global_position + Vector2(200.0, -34.0)
	strike.setup(player, mode)
	fx_root.add_child(strike)
	await strike.finished


func _unlock_portal(portal: Node, target_name: String) -> void:
	portal.set_active(true)
	hud.show_phase_banner("请前往下个区域", Color(0.42, 0.9, 1.0))
	hud.show_prompt("向右推进，进入 %s。" % target_name, 3.0)


func _on_portal_triggered(portal_id: StringName) -> void:
	if _portal_transition_requested:
		return
	if _stage_transition_running:
		return
	match portal_id:
		&"enemy":
			if GameState.current_stage == TUTORIAL_STAGE:
				_portal_transition_requested = true
				call_deferred("_transition_to_enemy")
		&"boss":
			if GameState.current_stage == ENEMY_STAGE and _enemy_sequence_started:
				_portal_transition_requested = true
				call_deferred("_transition_to_boss")


func _transition_to_enemy() -> void:
	_stage_transition_running = true
	enemy_portal.set_active(false)
	player.lock_for_cinematic()
	await hud.fade_to_black(0.5)
	Engine.time_scale = 1.0
	if get_tree().paused:
		get_tree().paused = false
		_menu_open = false
	hud.force_unblack()
	GameState.set_stage(ENEMY_STAGE)
	backdrop.set_stage(ENEMY_STAGE)
	_set_stage_label("废土残片 · 焦红僧侣")
	hud.clear_checklist()
	_set_zone(ENEMY_ZONE)
	player.global_position = Vector2(enemy_entry_spawn.global_position.x, GROUND_Y)
	player.refill_hp()
	player.set_no_damage_mode(false)
	await _cleanup_training_fx()
	_spawn_enemy()
	_snap_camera_to_player()
	_portal_transition_requested = false
	await hud.say("建木机器人", "没问题，那就先随即生成一个敌人吧……嗯，这是废土世界的僧侣，身体经过辐射后变得腐败溃烂，成了嗜血的怪物。", 2.9)
	await hud.say("建木机器人", "祝你好运。", 2.2)
	if enemy_ref != null:
		enemy_ref.activate(player)
	player.enable_control()
	_stage_transition_running = false
	EventBus.emit_game_event(&"flow.tutorial.end")
func _spawn_enemy() -> void:
	if enemy_ref != null:
		enemy_ref.queue_free()
	enemy_ref = ENEMY_SCENE.instantiate()
	$Arena/Actors.add_child(enemy_ref)
	var boosted_enemy_hp := int(enemy_ref.get("max_hp")) * 2
	enemy_ref.set("max_hp", boosted_enemy_hp)
	enemy_ref.set("hp", boosted_enemy_hp)
	if enemy_ref.has_method("emit_hp_changed"):
		enemy_ref.emit_hp_changed()
	enemy_ref.global_position = Vector2(enemy_fight_spawn.global_position.x, GROUND_Y)
	enemy_ref.defeated.connect(_on_enemy_defeated)
	EventBus.emit_game_event(&"enemy.spawned")


func _on_enemy_defeated() -> void:
	if _enemy_sequence_started:
		return
	_enemy_sequence_started = true
	call_deferred("_run_enemy_victory_sequence")


func _run_enemy_victory_sequence() -> void:
	player.lock_for_cinematic()
	player.refill_hp()
	await hud.say("建木机器人", "矫健的身手！你是我近期接待过的最好的测试人员，你曾经是士兵？", 2.7)
	await hud.say("主角", "不是。", 1.6)
	_unlock_portal(boss_portal, "红域裂口")
	player.enable_control()
	EventBus.emit_game_event(&"flow.enemy_wave.clear")
func _transition_to_boss() -> void:
	_stage_transition_running = true
	boss_portal.set_active(false)
	player.lock_for_cinematic()
	await hud.fade_to_black(0.55)
	Engine.time_scale = 1.0
	if get_tree().paused:
		get_tree().paused = false
		_menu_open = false
	hud.force_unblack()
	GameState.set_stage(BOSS_STAGE)
	backdrop.set_stage(BOSS_STAGE)
	_set_stage_label("红域裂口 · 克雷兹")
	_set_zone(BOSS_ZONE)
	player.global_position = Vector2(boss_entry_spawn.global_position.x, GROUND_Y)
	player.refill_hp()
	player.set_no_damage_mode(false)
	if enemy_ref != null:
		enemy_ref.queue_free()
		enemy_ref = null
	_spawn_boss()
	_play_stage_bgm(_boss_bgm, 0.55)
	_snap_camera_to_player()
	_portal_transition_requested = false
	await hud.say("建木机器人", "事不宜迟，就稍微调动算力来点令人兴奋的吧？是时候进入故事……滋滋！", 2.6)
	await hud.say("建木机器人", "Warning！Warning！", 1.5)
	await hud.say("癫狂的克雷兹", "哈哈哈哈哈哈哈哈！又有人来送死了！", 2.0)
	await hud.say("癫狂的克雷兹", "你不会是第一个死在这的！", 1.8)
	if boss_ref != null:
		boss_ref.activate(player)
	player.enable_control()
	_stage_transition_running = false
func _spawn_boss() -> void:
	if boss_ref != null:
		boss_ref.queue_free()
	boss_ref = BOSS_SCENE.instantiate()
	$Arena/Actors.add_child(boss_ref)
	var boosted_boss_hp := int(round(float(int(boss_ref.get("max_hp"))) * 1.5))
	boss_ref.set("max_hp", boosted_boss_hp)
	boss_ref.set("hp", boosted_boss_hp)
	if boss_ref.has_method("emit_hp_changed"):
		boss_ref.emit_hp_changed()
	boss_ref.global_position = Vector2(boss_fight_spawn.global_position.x, GROUND_Y)
	boss_ref.hp_changed.connect(hud.set_boss_hp)
	boss_ref.phase_changed.connect(_on_boss_phase_changed)
	boss_ref.defeated.connect(_on_boss_defeated)
	hud.show_boss_bar("癫狂的克雷兹", boss_ref.max_hp)
	hud.set_boss_hp(boss_ref.max_hp, boss_ref.max_hp)
	EventBus.emit_game_event(&"flow.boss.start")


func _on_boss_phase_changed(phase: int) -> void:
	var phase_text := ""
	var tint := Color(1.0, 0.24, 0.24)
	match phase:
		2:
			phase_text = "阶段 II · 失控增压"
			tint = Color(1.0, 0.48, 0.24)
			player.refill_hp()
			call_deferred("_play_phase_dialogue", phase)
		3:
			phase_text = "阶段 III · 深红爆发"
			tint = Color(1.0, 0.18, 0.18)
			player.refill_hp()
			call_deferred("_play_phase_dialogue", phase)
		_:
			phase_text = "阶段 I · 试探"
	hud.show_phase_banner(phase_text, tint)


func _play_phase_dialogue(phase: int) -> void:
	match phase:
		2:
			await hud.say("癫狂的克雷兹", "疼……好疼……但我喜欢！！！", 1.8)
		3:
			await hud.say("癫狂的克雷兹", "杀了我……然后你也一起来！！！", 2.0)
func _on_boss_defeated() -> void:
	if _boss_sequence_started:
		return
	_boss_sequence_started = true
	call_deferred("_run_boss_defeat_sequence")


func _run_boss_defeat_sequence() -> void:
	player.lock_for_cinematic()
	hud.hide_boss_bar()
	await hud.say("癫狂的克雷兹", "结束！结束！这是开始！", 2.1)
	await _run_collapse_sequence()
func _run_collapse_sequence() -> void:
	if _collapse_running:
		return
	_collapse_running = true
	_stop_bgm(0.7)
	GameState.set_stage(COLLAPSE_STAGE)
	EventBus.emit_game_event(&"flow.boss.defeated")
	EventBus.emit_game_event(&"flow.collapse.start")
	backdrop.set_stage(COLLAPSE_STAGE)
	backdrop.set_collapse_city(0)
	_set_stage_label("下坠频闪 · 四界流光")
	bot.set_disabled(true)
	var collapse_names := [
		["桥都", Color(0.4, 0.82, 1.0)],
		["石锈镇", Color(0.96, 0.72, 0.36)],
		["龙溪", Color(0.66, 0.9, 0.86)],
		["烬城", Color(0.98, 0.32, 0.22)]
	]
	for segment_index in range(collapse_names.size()):
		backdrop.set_collapse_progress(float(segment_index) / float(collapse_names.size()))
		backdrop.set_collapse_city(segment_index)
		hud.show_phase_banner(collapse_names[segment_index][0], collapse_names[segment_index][1])
		EventBus.emit_game_event(&"flow.fall.segment_changed", {
			"index": segment_index,
			"city": collapse_names[segment_index][0]
		})
		TimeDirector.request_shake(180 + segment_index * 35, 9.0 + segment_index * 2.0)
		hud.flash(Color(0.0, 0.0, 0.0), 120 + segment_index * 20, 0.5)
		await get_tree().create_timer(0.95, true, false, true).timeout
	hud.show_inner_text("那是……什么？", 2.0)
	await get_tree().create_timer(2.2, true, false, true).timeout
	player.visible = false
	await hud.fade_to_black(0.8)
	await _run_ending_sequence()


func _run_ending_sequence() -> void:
	GameState.set_stage(ENDING_STAGE)
	backdrop.set_stage(ENDING_STAGE)
	_set_stage_label("结幕 · 星球与建木")
	await hud.fade_from_black(0.9)
	await hud.show_title("建木行者", "", 2.8)
	await hud.say("建木机器人", "这是……我们世界的第一次建交……通过建木……", 2.6)
	hud.flash(Color(0.0, 0.0, 0.0), 220, 0.72)
	TimeDirector.request_shake(260, 12.0)
	hud.show_prompt("Enter 重新开始  Esc 退出", 999.0)
	EventBus.emit_game_event(&"flow.demo.end")


func _cleanup_training_fx() -> void:
	for child in fx_root.get_children():
		if child.has_signal("finished"):
			child.queue_free()
	await get_tree().process_frame


func _mark_tutorial(key: StringName) -> void:
	tutorial_done[key] = true
	var index := tutorial_keys.find(key)
	if index >= 0:
		hud.set_check(index, true)


func _basic_tutorial_done() -> bool:
	return tutorial_done[&"attack"] and tutorial_done[&"dodge"] and tutorial_done[&"guard"]


func _on_player_dead() -> void:
	if _stage_transition_running or GameState.current_stage == TUTORIAL_STAGE:
		call_deferred("_recover_player_from_transition_fault")
		return
	call_deferred("_handle_player_dead")


func _handle_player_dead() -> void:
	if _menu_open:
		_close_exit_menu()
	await hud.fade_to_black(0.65)
	get_tree().reload_current_scene()


func _recover_player_from_transition_fault() -> void:
	Engine.time_scale = 1.0
	if get_tree().paused:
		get_tree().paused = false
		_menu_open = false
	hud.force_unblack()
	_stage_transition_running = false
	_portal_transition_requested = false
	player.force_recover_for_flow(GameState.current_stage == TUTORIAL_STAGE)


func _open_exit_menu() -> void:
	_menu_open = true
	hud.show_exit_menu(_current_stage_label)
	get_tree().paused = true


func _close_exit_menu() -> void:
	get_tree().paused = false
	_menu_open = false
	hud.hide_exit_menu()


func _set_zone(bounds: Vector2) -> void:
	_current_zone = bounds


func _snap_camera_to_player() -> void:
	camera.global_position = Vector2(_get_camera_target_x(player.global_position.x), 360.0)
	camera.offset = Vector2.ZERO


func _get_camera_target_x(focus_x: float) -> float:
	var half_width := _get_camera_half_width()
	var min_center := _current_zone.x + half_width + CAMERA_EDGE_MARGIN
	var max_center := _current_zone.y - half_width - CAMERA_EDGE_MARGIN
	if min_center > max_center:
		return (_current_zone.x + _current_zone.y) * 0.5
	return clampf(focus_x, min_center, max_center)


func _clamp_camera_offset(offset: Vector2, center_x: float) -> Vector2:
	var clamped := offset
	var half_width := _get_camera_half_width()
	var min_center := _current_zone.x + half_width + CAMERA_EDGE_MARGIN
	var max_center := _current_zone.y - half_width - CAMERA_EDGE_MARGIN
	if min_center > max_center:
		clamped.x = 0.0
		return clamped
	var min_offset := min_center - center_x
	var max_offset := max_center - center_x
	clamped.x = clampf(clamped.x, min_offset, max_offset)
	return clamped


func _get_camera_half_width() -> float:
	return get_viewport_rect().size.x * 0.5


func _check_portal_proximity_fallback() -> void:
	if _portal_transition_requested:
		return
	if _menu_open:
		return
	match GameState.current_stage:
		TUTORIAL_STAGE:
			if enemy_portal.has_method("is_active") and enemy_portal.is_active():
				if _is_player_near_portal(enemy_portal.global_position):
					_on_portal_triggered(&"enemy")
		ENEMY_STAGE:
			if _enemy_sequence_started and boss_portal.has_method("is_active") and boss_portal.is_active():
				if _is_player_near_portal(boss_portal.global_position):
					_on_portal_triggered(&"boss")
		_:
			pass


func _is_player_near_portal(portal_position: Vector2) -> bool:
	var close_x := absf(player.global_position.x - portal_position.x) <= 74.0
	var close_y := absf(player.global_position.y - portal_position.y) <= 130.0
	return close_x and close_y


func _set_stage_label(text: String) -> void:
	_current_stage_label = text
	hud.set_stage_label(text)


func _load_bgm_tracks() -> void:
	_normal_bgm = _load_first_stream(NORMAL_BGM_CANDIDATES)
	_boss_bgm = _load_first_stream(BOSS_BGM_CANDIDATES)
	bgm_player.volume_db = -13.0


func _play_stage_bgm(stream: AudioStream, fade_duration: float = 0.45) -> void:
	if stream == null:
		return
	if bgm_player.stream == stream and bgm_player.playing:
		return
	if _bgm_tween != null:
		_bgm_tween.kill()
	if not bgm_player.playing or fade_duration <= 0.0:
		bgm_player.stream = stream
		bgm_player.volume_db = -13.0
		bgm_player.play()
		return
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(bgm_player, "volume_db", -28.0, fade_duration * 0.45)
	_bgm_tween.tween_callback(func() -> void:
		bgm_player.stream = stream
		bgm_player.play()
	)
	_bgm_tween.tween_property(bgm_player, "volume_db", -13.0, fade_duration * 0.55)


func _stop_bgm(fade_duration: float = 0.4) -> void:
	if not bgm_player.playing:
		return
	if _bgm_tween != null:
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(bgm_player, "volume_db", -36.0, fade_duration)
	_bgm_tween.tween_callback(func() -> void:
		bgm_player.stop()
		bgm_player.volume_db = -13.0
	)


func _load_first_stream(paths: Array) -> AudioStream:
	for path in paths:
		if ResourceLoader.exists(path):
			var stream := load(path)
			if stream is AudioStream:
				return stream
	return null


func _ensure_input_map() -> void:
	_bind_key(&"move_left", KEY_A)
	_bind_key(&"move_left", KEY_LEFT)
	_bind_key(&"move_right", KEY_D)
	_bind_key(&"move_right", KEY_RIGHT)
	_bind_key(&"jump", KEY_SPACE)
	_bind_key(&"jump", KEY_W)
	_bind_key(&"jump", KEY_UP)
	_bind_key(&"attack", KEY_J)
	_bind_key(&"attack", KEY_Z)
	_bind_key(&"dodge", KEY_K)
	_bind_key(&"dodge", KEY_X)
	_bind_key(&"guard", KEY_L)
	_bind_key(&"guard", KEY_C)
	_bind_key(&"confirm", KEY_ENTER)
	_bind_key(&"pause_menu", KEY_ESCAPE)
	_remove_key(&"confirm", KEY_SPACE)
	_remove_key(&"pause", KEY_R)


func _bind_key(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and (event.keycode == keycode or event.physical_keycode == keycode):
			return
	var input_event := InputEventKey.new()
	input_event.keycode = keycode
	input_event.physical_keycode = keycode
	InputMap.action_add_event(action_name, input_event)


func _remove_key(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		return
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and (event.keycode == keycode or event.physical_keycode == keycode):
			InputMap.action_erase_event(action_name, event)



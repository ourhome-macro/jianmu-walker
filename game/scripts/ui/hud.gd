extends CanvasLayer

var root_control: Control
var fade_rect: ColorRect
var flash_rect: ColorRect
var title_badge: PanelContainer
var game_title_label: Label
var game_subtitle_label: Label
var prompt_label: Label
var speaker_label: Label
var body_label: Label
var dialogue_panel: PanelContainer
var checklist_panel: PanelContainer
var checklist_box: VBoxContainer
var checklist_labels: Array[Label] = []
var player_bar: ProgressBar
var player_hp_label: Label
var boss_panel: PanelContainer
var boss_name_label: Label
var boss_bar: ProgressBar
var stage_label: Label
var phase_banner: Label
var title_label: Label
var subtitle_label: Label
var inner_voice_label: Label
var pause_hint_label: Label
var pause_panel: PanelContainer
var pause_stage_label: Label
var pause_body_label: Label


func _ready() -> void:
	layer = 10
	_build_ui()
	set_game_title("建木行者", "Jianmu Walker")


func set_stage_label(text: String) -> void:
	stage_label.text = text
	pause_stage_label.text = text


func set_game_title(title: String, subtitle: String = "") -> void:
	game_title_label.text = title
	game_subtitle_label.text = subtitle


func set_player_hp(current_hp: int, max_hp: int) -> void:
	player_bar.max_value = max_hp
	player_bar.value = current_hp
	player_hp_label.text = "HP %d / %d" % [current_hp, max_hp]


func show_boss_bar(title: String, max_hp: int) -> void:
	boss_panel.visible = true
	boss_name_label.text = title
	boss_bar.max_value = max_hp
	boss_bar.value = max_hp


func set_boss_hp(current_hp: int, max_hp: int) -> void:
	boss_bar.max_value = max_hp
	boss_bar.value = current_hp


func hide_boss_bar() -> void:
	boss_panel.visible = false


func show_exit_menu(stage_text: String) -> void:
	pause_panel.visible = true
	pause_stage_label.text = stage_text
	pause_panel.modulate = Color.WHITE


func hide_exit_menu() -> void:
	pause_panel.visible = false


func set_checklist(items: Array) -> void:
	for child in checklist_box.get_children():
		child.queue_free()
	checklist_labels.clear()
	if items.is_empty():
		checklist_panel.visible = false
		return
	checklist_panel.visible = true
	for item_text in items:
		var label := Label.new()
		label.label_settings = _make_label_settings(20, Color(0.93, 0.97, 1.0), 6, Color(0.02, 0.03, 0.07, 0.85))
		label.text = "• %s" % item_text
		checklist_box.add_child(label)
		checklist_labels.append(label)


func clear_checklist() -> void:
	set_checklist([])


func set_check(index: int, done: bool) -> void:
	if index < 0 or index >= checklist_labels.size():
		return
	var label := checklist_labels[index]
	var suffix := label.text.substr(2)
	label.text = "%s %s" % ["✓" if done else "•", suffix]
	label.modulate = Color(0.72, 1.0, 0.86, 1.0) if done else Color.WHITE


func show_prompt(text: String, duration: float = 1.6) -> void:
	prompt_label.text = text
	prompt_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(prompt_label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(duration)
	tween.tween_property(prompt_label, "modulate:a", 0.0, 0.25)


func show_inner_text(text: String, duration: float = 1.8) -> void:
	inner_voice_label.text = text
	inner_voice_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(inner_voice_label, "modulate:a", 1.0, 0.22)
	tween.tween_interval(duration)
	tween.tween_property(inner_voice_label, "modulate:a", 0.0, 0.28)


func show_typewriter_text(text: String, char_interval: float = 0.075, hold: float = 2.0) -> void:
	inner_voice_label.text = ""
	inner_voice_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	for index in range(text.length()):
		inner_voice_label.text = text.substr(0, index + 1)
		await get_tree().create_timer(char_interval, true, false, true).timeout
	await get_tree().create_timer(hold, true, false, true).timeout
	var tween := create_tween()
	tween.tween_property(inner_voice_label, "modulate:a", 0.0, 0.45)
	await tween.finished


func say(speaker: String, body: String, duration: float = 2.4) -> void:
	dialogue_panel.visible = true
	speaker_label.text = speaker
	body_label.text = body
	dialogue_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(dialogue_panel, "modulate:a", 1.0, 0.18)
	await tween.finished
	await get_tree().create_timer(duration, true, false, true).timeout
	var out_tween := create_tween()
	out_tween.tween_property(dialogue_panel, "modulate:a", 0.0, 0.2)
	await out_tween.finished
	dialogue_panel.visible = false


func flash(color: Color, duration_ms: int = 120, max_alpha: float = 0.9) -> void:
	flash_rect.color = Color(color.r, color.g, color.b, max_alpha)
	flash_rect.visible = true
	var tween := create_tween()
	tween.tween_property(flash_rect, "color", Color(color.r, color.g, color.b, 0.0), duration_ms / 1000.0)
	tween.finished.connect(func() -> void:
		flash_rect.visible = false
	)


func fade_from_black(duration: float = 0.8) -> void:
	fade_rect.visible = true
	fade_rect.color = Color(0.01, 0.02, 0.03, 1.0)
	var tween := create_tween()
	tween.tween_property(fade_rect, "color", Color(0.01, 0.02, 0.03, 0.0), duration)
	await tween.finished
	fade_rect.visible = false


func fade_to_black(duration: float = 0.8) -> void:
	fade_rect.visible = true
	fade_rect.color = Color(0.01, 0.02, 0.03, 0.0)
	var tween := create_tween()
	tween.tween_property(fade_rect, "color", Color(0.01, 0.02, 0.03, 1.0), duration)
	await tween.finished


func force_unblack() -> void:
	if fade_rect == null:
		return
	fade_rect.visible = false
	fade_rect.color = Color(0.01, 0.02, 0.03, 0.0)


func show_phase_banner(text: String, tint: Color = Color(1.0, 0.2, 0.2)) -> void:
	phase_banner.text = text
	phase_banner.label_settings.font_color = tint
	phase_banner.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(phase_banner, "modulate:a", 1.0, 0.18)
	tween.tween_interval(1.15)
	tween.tween_property(phase_banner, "modulate:a", 0.0, 0.26)


func show_title(title: String, subtitle: String = "", duration: float = 2.4) -> void:
	title_label.text = title
	subtitle_label.text = subtitle
	title_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	subtitle_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.26)
	tween.parallel().tween_property(subtitle_label, "modulate:a", 1.0, 0.28)
	tween.tween_interval(duration)
	tween.tween_property(title_label, "modulate:a", 0.0, 0.32)
	tween.parallel().tween_property(subtitle_label, "modulate:a", 0.0, 0.32)
	await tween.finished


func _build_ui() -> void:
	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_control)

	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.0, 0.0, 0.0, 0.18)
	root_control.add_child(vignette)

	title_badge = PanelContainer.new()
	title_badge.offset_left = 24.0
	title_badge.offset_top = 18.0
	title_badge.offset_right = 286.0
	title_badge.offset_bottom = 84.0
	title_badge.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.05, 0.09, 0.78), Color(0.35, 0.8, 0.96, 0.28)))
	root_control.add_child(title_badge)

	var title_margin := MarginContainer.new()
	title_margin.add_theme_constant_override("margin_left", 14)
	title_margin.add_theme_constant_override("margin_top", 10)
	title_margin.add_theme_constant_override("margin_right", 14)
	title_margin.add_theme_constant_override("margin_bottom", 8)
	title_badge.add_child(title_margin)

	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 2)
	title_margin.add_child(title_box)

	game_title_label = Label.new()
	game_title_label.label_settings = _make_label_settings(26, Color(0.95, 0.99, 1.0), 6, Color(0.01, 0.02, 0.04, 0.92))
	title_box.add_child(game_title_label)

	game_subtitle_label = Label.new()
	game_subtitle_label.label_settings = _make_label_settings(12, Color(0.7, 0.92, 1.0), 4, Color(0.01, 0.02, 0.04, 0.92))
	title_box.add_child(game_subtitle_label)

	stage_label = Label.new()
	stage_label.label_settings = _make_label_settings(18, Color(0.82, 0.9, 0.98), 5, Color(0.02, 0.03, 0.07, 0.85))
	stage_label.anchor_left = 1.0
	stage_label.anchor_right = 1.0
	stage_label.offset_left = -280.0
	stage_label.offset_top = 18.0
	stage_label.offset_right = -24.0
	stage_label.offset_bottom = 52.0
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stage_label.text = ""
	root_control.add_child(stage_label)

	prompt_label = Label.new()
	prompt_label.label_settings = _make_label_settings(22, Color(0.95, 0.98, 1.0), 8, Color(0.02, 0.03, 0.07, 0.92))
	prompt_label.anchor_left = 0.5
	prompt_label.anchor_right = 0.5
	prompt_label.offset_left = -320.0
	prompt_label.offset_top = 58.0
	prompt_label.offset_right = 320.0
	prompt_label.offset_bottom = 108.0
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	root_control.add_child(prompt_label)

	checklist_panel = PanelContainer.new()
	checklist_panel.anchor_left = 0.0
	checklist_panel.anchor_top = 0.0
	checklist_panel.offset_left = 24.0
	checklist_panel.offset_top = 98.0
	checklist_panel.offset_right = 320.0
	checklist_panel.offset_bottom = 294.0
	checklist_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.05, 0.09, 0.78), Color(0.31, 0.66, 0.9, 0.32)))
	root_control.add_child(checklist_panel)
	checklist_box = VBoxContainer.new()
	checklist_box.add_theme_constant_override("separation", 8)
	checklist_panel.add_child(checklist_box)
	checklist_panel.visible = false

	dialogue_panel = PanelContainer.new()
	dialogue_panel.anchor_left = 0.5
	dialogue_panel.anchor_top = 1.0
	dialogue_panel.anchor_right = 0.5
	dialogue_panel.anchor_bottom = 1.0
	dialogue_panel.offset_left = -340.0
	dialogue_panel.offset_top = -170.0
	dialogue_panel.offset_right = 340.0
	dialogue_panel.offset_bottom = -34.0
	dialogue_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.05, 0.09, 0.84), Color(0.35, 0.8, 0.96, 0.28)))
	dialogue_panel.visible = false
	root_control.add_child(dialogue_panel)

	var dialogue_margin := MarginContainer.new()
	dialogue_margin.add_theme_constant_override("margin_left", 18)
	dialogue_margin.add_theme_constant_override("margin_top", 14)
	dialogue_margin.add_theme_constant_override("margin_right", 18)
	dialogue_margin.add_theme_constant_override("margin_bottom", 14)
	dialogue_panel.add_child(dialogue_margin)

	var dialogue_box := VBoxContainer.new()
	dialogue_box.add_theme_constant_override("separation", 6)
	dialogue_margin.add_child(dialogue_box)

	speaker_label = Label.new()
	speaker_label.label_settings = _make_label_settings(18, Color(0.52, 0.96, 1.0), 5, Color(0.01, 0.01, 0.04, 0.8))
	dialogue_box.add_child(speaker_label)

	body_label = Label.new()
	body_label.label_settings = _make_label_settings(24, Color(0.96, 0.98, 1.0), 5, Color(0.01, 0.01, 0.04, 0.92))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_box.add_child(body_label)

	var player_panel := PanelContainer.new()
	player_panel.anchor_left = 0.0
	player_panel.anchor_top = 1.0
	player_panel.offset_left = 24.0
	player_panel.offset_top = -92.0
	player_panel.offset_right = 300.0
	player_panel.offset_bottom = -24.0
	player_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.05, 0.08, 0.82), Color(0.22, 0.74, 0.92, 0.28)))
	root_control.add_child(player_panel)

	var player_margin := MarginContainer.new()
	player_margin.add_theme_constant_override("margin_left", 14)
	player_margin.add_theme_constant_override("margin_top", 10)
	player_margin.add_theme_constant_override("margin_right", 14)
	player_margin.add_theme_constant_override("margin_bottom", 10)
	player_panel.add_child(player_margin)

	var player_vbox := VBoxContainer.new()
	player_vbox.add_theme_constant_override("separation", 6)
	player_margin.add_child(player_vbox)

	player_hp_label = Label.new()
	player_hp_label.label_settings = _make_label_settings(18, Color(0.88, 0.96, 1.0), 4, Color(0.01, 0.02, 0.04, 0.9))
	player_vbox.add_child(player_hp_label)

	player_bar = ProgressBar.new()
	player_bar.min_value = 0.0
	player_bar.max_value = 100.0
	player_bar.value = 100.0
	player_bar.show_percentage = false
	player_bar.custom_minimum_size = Vector2(0.0, 20.0)
	player_bar.add_theme_stylebox_override("fill", _make_bar_style(Color(0.26, 0.86, 0.96, 0.95)))
	player_bar.add_theme_stylebox_override("background", _make_bar_style(Color(0.08, 0.1, 0.14, 0.95)))
	player_vbox.add_child(player_bar)

	boss_panel = PanelContainer.new()
	boss_panel.anchor_left = 0.5
	boss_panel.anchor_right = 0.5
	boss_panel.offset_left = -320.0
	boss_panel.offset_top = 24.0
	boss_panel.offset_right = 320.0
	boss_panel.offset_bottom = 92.0
	boss_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.11, 0.02, 0.03, 0.8), Color(0.92, 0.24, 0.21, 0.3)))
	boss_panel.visible = false
	root_control.add_child(boss_panel)

	var boss_margin := MarginContainer.new()
	boss_margin.add_theme_constant_override("margin_left", 14)
	boss_margin.add_theme_constant_override("margin_top", 10)
	boss_margin.add_theme_constant_override("margin_right", 14)
	boss_margin.add_theme_constant_override("margin_bottom", 10)
	boss_panel.add_child(boss_margin)

	var boss_vbox := VBoxContainer.new()
	boss_vbox.add_theme_constant_override("separation", 6)
	boss_margin.add_child(boss_vbox)

	boss_name_label = Label.new()
	boss_name_label.label_settings = _make_label_settings(18, Color(1.0, 0.86, 0.84), 5, Color(0.07, 0.01, 0.01, 0.9))
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_vbox.add_child(boss_name_label)

	boss_bar = ProgressBar.new()
	boss_bar.min_value = 0.0
	boss_bar.max_value = 100.0
	boss_bar.value = 100.0
	boss_bar.show_percentage = false
	boss_bar.custom_minimum_size = Vector2(0.0, 22.0)
	boss_bar.add_theme_stylebox_override("fill", _make_bar_style(Color(0.95, 0.24, 0.24, 0.96)))
	boss_bar.add_theme_stylebox_override("background", _make_bar_style(Color(0.18, 0.05, 0.05, 0.95)))
	boss_vbox.add_child(boss_bar)

	phase_banner = Label.new()
	phase_banner.anchor_left = 0.5
	phase_banner.anchor_right = 0.5
	phase_banner.offset_left = -280.0
	phase_banner.offset_top = 120.0
	phase_banner.offset_right = 280.0
	phase_banner.offset_bottom = 168.0
	phase_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_banner.label_settings = _make_label_settings(28, Color(1.0, 0.26, 0.26), 8, Color(0.04, 0.01, 0.02, 0.9))
	phase_banner.modulate = Color(1.0, 1.0, 1.0, 0.0)
	root_control.add_child(phase_banner)

	inner_voice_label = Label.new()
	inner_voice_label.anchor_left = 0.5
	inner_voice_label.anchor_top = 0.72
	inner_voice_label.anchor_right = 0.5
	inner_voice_label.anchor_bottom = 0.72
	inner_voice_label.offset_left = -260.0
	inner_voice_label.offset_top = -20.0
	inner_voice_label.offset_right = 260.0
	inner_voice_label.offset_bottom = 26.0
	inner_voice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_voice_label.label_settings = _make_label_settings(18, Color(0.86, 0.92, 1.0), 5, Color(0.01, 0.02, 0.04, 0.92))
	inner_voice_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	root_control.add_child(inner_voice_label)

	title_label = Label.new()
	title_label.anchor_left = 0.5
	title_label.anchor_top = 0.5
	title_label.anchor_right = 0.5
	title_label.anchor_bottom = 0.5
	title_label.offset_left = -320.0
	title_label.offset_top = -96.0
	title_label.offset_right = 320.0
	title_label.offset_bottom = -20.0
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.label_settings = _make_label_settings(46, Color(0.94, 0.99, 1.0), 12, Color(0.01, 0.02, 0.05, 0.95))
	title_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	root_control.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.anchor_left = 0.5
	subtitle_label.anchor_top = 0.5
	subtitle_label.anchor_right = 0.5
	subtitle_label.anchor_bottom = 0.5
	subtitle_label.offset_left = -320.0
	subtitle_label.offset_top = -12.0
	subtitle_label.offset_right = 320.0
	subtitle_label.offset_bottom = 40.0
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.label_settings = _make_label_settings(20, Color(0.72, 0.92, 1.0), 6, Color(0.01, 0.02, 0.05, 0.9))
	subtitle_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	root_control.add_child(subtitle_label)

	pause_hint_label = Label.new()
	pause_hint_label.anchor_left = 1.0
	pause_hint_label.anchor_top = 1.0
	pause_hint_label.anchor_right = 1.0
	pause_hint_label.anchor_bottom = 1.0
	pause_hint_label.offset_left = -188.0
	pause_hint_label.offset_top = -52.0
	pause_hint_label.offset_right = -24.0
	pause_hint_label.offset_bottom = -24.0
	pause_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pause_hint_label.label_settings = _make_label_settings(16, Color(0.78, 0.92, 1.0), 4, Color(0.01, 0.02, 0.04, 0.88))
	pause_hint_label.text = "Esc 菜单"
	root_control.add_child(pause_hint_label)

	pause_panel = PanelContainer.new()
	pause_panel.anchor_left = 0.5
	pause_panel.anchor_top = 0.5
	pause_panel.anchor_right = 0.5
	pause_panel.anchor_bottom = 0.5
	pause_panel.offset_left = -250.0
	pause_panel.offset_top = -140.0
	pause_panel.offset_right = 250.0
	pause_panel.offset_bottom = 140.0
	pause_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.05, 0.09, 0.9), Color(0.34, 0.84, 1.0, 0.36)))
	pause_panel.visible = false
	root_control.add_child(pause_panel)

	var pause_margin := MarginContainer.new()
	pause_margin.add_theme_constant_override("margin_left", 20)
	pause_margin.add_theme_constant_override("margin_top", 18)
	pause_margin.add_theme_constant_override("margin_right", 20)
	pause_margin.add_theme_constant_override("margin_bottom", 18)
	pause_panel.add_child(pause_margin)

	var pause_box := VBoxContainer.new()
	pause_box.add_theme_constant_override("separation", 8)
	pause_margin.add_child(pause_box)

	var pause_title := Label.new()
	pause_title.label_settings = _make_label_settings(32, Color(0.95, 0.99, 1.0), 8, Color(0.01, 0.02, 0.04, 0.92))
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.text = "建木行者"
	pause_box.add_child(pause_title)

	pause_stage_label = Label.new()
	pause_stage_label.label_settings = _make_label_settings(18, Color(0.68, 0.92, 1.0), 4, Color(0.01, 0.02, 0.04, 0.92))
	pause_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_box.add_child(pause_stage_label)

	pause_body_label = Label.new()
	pause_body_label.label_settings = _make_label_settings(18, Color(0.94, 0.98, 1.0), 5, Color(0.01, 0.02, 0.04, 0.92))
	pause_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_body_label.text = "Esc 返回游戏\nEnter 退出游戏"
	pause_box.add_child(pause_body_label)

	flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	flash_rect.visible = false
	root_control.add_child(flash_rect)

	fade_rect = ColorRect.new()
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0.01, 0.02, 0.03, 1.0)
	root_control.add_child(fade_rect)


func _make_panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	return style


func _make_bar_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _make_label_settings(font_size: int, font_color: Color, outline: int, outline_color: Color) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = font_color
	settings.outline_size = outline
	settings.outline_color = outline_color
	return settings

extends Node

signal stage_changed(stage_name: StringName)
signal boss_phase_changed(phase: int)

var current_stage: StringName = &"boot"
var boss_phase: int = 1
var tutorial_flags: Dictionary = {}


func reset_demo() -> void:
	current_stage = &"boot"
	boss_phase = 1
	tutorial_flags.clear()
	stage_changed.emit(current_stage)
	boss_phase_changed.emit(boss_phase)


func set_stage(stage_name: StringName) -> void:
	if current_stage == stage_name:
		return
	current_stage = stage_name
	stage_changed.emit(current_stage)


func set_boss_phase(phase: int) -> void:
	if boss_phase == phase:
		return
	boss_phase = phase
	boss_phase_changed.emit(boss_phase)


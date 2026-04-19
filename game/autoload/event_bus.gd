extends Node

signal event_emitted(event_name: StringName, payload: Dictionary)

var _once_flags: Dictionary = {}


func emit_game_event(event_name: StringName, payload: Dictionary = {}, once_key: String = "") -> void:
	if once_key != "" and _once_flags.has(once_key):
		return
	if once_key != "":
		_once_flags[once_key] = true
	event_emitted.emit(event_name, payload)


func clear_once_flags() -> void:
	_once_flags.clear()


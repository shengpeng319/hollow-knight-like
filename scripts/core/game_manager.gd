extends Node

var _is_paused: bool = false
var _is_game_over: bool = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	_is_paused = not _is_paused
	get_tree().paused = _is_paused

func game_over() -> void:
	_is_game_over = true
	get_tree().paused = true

func restart_game() -> void:
	_is_game_over = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func is_paused() -> bool:
	return _is_paused

func is_game_over() -> bool:
	return _is_game_over

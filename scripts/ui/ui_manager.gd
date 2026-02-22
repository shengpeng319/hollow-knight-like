extends Node

@export_group("Health Display")
@export var health_container: HBoxContainer
@export var health_icon: PackedScene

var _current_health_display: int = -1
var _max_health_display: int = -1
var _start_panel: Panel
var _game_over_panel: Panel

func _ready() -> void:
	_start_panel = get_node_or_null("StartPanel")
	_game_over_panel = get_node_or_null("GameOverPanel")
	
	if _start_panel:
		_start_panel.show()
		var start_button = _start_panel.get_node("StartButton")
		if start_button:
			start_button.pressed.connect(_on_start_pressed)
	
	if _game_over_panel:
		_game_over_panel.hide()
		var restart_button = _game_over_panel.get_node("RestartButton")
		if restart_button:
			restart_button.pressed.connect(_on_restart_pressed)
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		player.player_died.connect(_on_player_died)

func _on_start_pressed() -> void:
	print("Start button pressed!")
	if _start_panel:
		_start_panel.hide()

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_health_changed(current: int, maximum: int) -> void:
	if _current_health_display == current and _max_health_display == maximum:
		return
	
	_current_health_display = current
	_max_health_display = maximum
	
	if health_container:
		for child in health_container.get_children():
			child.queue_free()
		
		for i in range(maximum):
			var icon = health_icon.instantiate() if health_icon else TextureRect.new()
			icon.custom_minimum_size = Vector2(20, 20)
			
			if not health_icon:
				var color_rect = ColorRect.new()
				color_rect.color = Color.RED if i < current else Color.DIM_GRAY
				color_rect.custom_minimum_size = Vector2(20, 20)
				icon.add_child(color_rect)
			
			health_container.add_child(icon)

func _on_player_died() -> void:
	if _game_over_panel:
		_game_over_panel.show()

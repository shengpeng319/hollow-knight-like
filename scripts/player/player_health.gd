extends CharacterBody2D
class_name PlayerHealth

signal health_changed(current: int, maximum: int)
signal player_died

@export_group("Health Settings")
@export var max_health: int = 5
@export var invincibility_duration: float = 1.0
@export var knockback_force: float = 300.0

var _current_health: int
var _is_invincible: bool = false
var _start_position: Vector2

@onready var _sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	_current_health = max_health
	_start_position = global_position
	health_changed.emit(_current_health, max_health)

func take_damage(damage: float) -> void:
	if _is_invincible:
		return
	
	_current_health -= int(damage)
	_current_health = max(0, _current_health)
	health_changed.emit(_current_health, max_health)
	
	if _current_health <= 0:
		_die()
	else:
		_apply_knockback()
		_start_invincibility()

func _apply_knockback() -> void:
	var direction = sign(global_position.x - _start_position.x) if global_position.x != _start_position.x else 1
	velocity = Vector2(direction * knockback_force, -knockback_force * 0.3)

func _start_invincibility() -> void:
	_is_invincible = true
	await get_tree().create_timer(invincibility_duration).timeout
	_is_invincible = false

func _die() -> void:
	set_physics_process(false)
	set_process(false)
	player_died.emit()
	
	await get_tree().create_timer(2.0).timeout
	_respawn()

func _respawn() -> void:
	global_position = _start_position
	_current_health = max_health
	health_changed.emit(_current_health, max_health)
	
	set_physics_process(true)
	set_process(true)
	
	velocity = Vector2.ZERO

func heal(amount: int) -> void:
	_current_health = min(_current_health + amount, max_health)
	health_changed.emit(_current_health, max_health)

func get_current_health() -> int:
	return _current_health

func get_max_health() -> int:
	return max_health

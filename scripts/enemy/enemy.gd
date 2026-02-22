extends CharacterBody2D
class_name Enemy

signal died

@export_group("Movement Settings")
@export var move_speed: float = 80.0
@export var patrol_distance: float = 100.0
@export var chase_distance: float = 200.0
@export var attack_distance: float = 50.0

@export_group("Attack Settings")
@export var attack_damage: float = 1.0
@export var attack_cooldown: float = 1.5
@export var attack_point: Node2D
@export var attack_range: float = 40.0

@export_group("Health Settings")
@export var max_health: int = 2
@export var knockback_force: float = 150.0

var _current_health: int
var _is_dead: bool = false
var _can_attack: bool = true
var _patrol_direction: int = 1
var _start_position: Vector2
var _player: Node2D = null

@onready var _sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	_current_health = max_health
	_start_position = global_position
	_patrol_direction = 1 if randf() > 0.5 else -1

func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	
	_find_player()
	
	if _player:
		var distance_to_player = global_position.distance_to(_player.global_position)
		
		if distance_to_player <= chase_distance:
			_chase_player(distance_to_player)
		else:
			_patrol()
	else:
		_patrol()

func _find_player() -> void:
	if _player:
		return
	_player = get_tree().get_first_node_in_group("player")

func _patrol() -> void:
	velocity.x = _patrol_direction * move_speed
	
	if global_position.x > _start_position.x + patrol_distance:
		_patrol_direction = -1
	elif global_position.x < _start_position.x - patrol_distance:
		_patrol_direction = 1
	
	move_and_slide()

func _chase_player(distance_to_player: float) -> void:
	var direction = sign(_player.global_position.x - global_position.x)
	velocity.x = direction * move_speed * 1.5
	
	if distance_to_player <= attack_distance:
		_attack()
	
	move_and_slide()

func _attack() -> void:
	if not _can_attack:
		return
	
	_can_attack = false
	_detect_player()
	
	await get_tree().create_timer(attack_cooldown).timeout
	_can_attack = true

func _detect_player() -> void:
	if not attack_point or not _player:
		return
	
	if global_position.distance_to(_player.global_position) <= attack_range:
		if _player.has_method("take_damage"):
			_player.take_damage(attack_damage)

func take_damage(damage: float) -> void:
	if _is_dead:
		return
	
	_current_health -= int(damage)
	_current_health = max(0, _current_health)
	
	if _current_health <= 0:
		_die()
	else:
		_apply_knockback()

func _apply_knockback() -> void:
	var direction = -sign(velocity.x) if velocity.x != 0 else -_patrol_direction
	velocity = Vector2(direction * knockback_force, -knockback_force * 0.3)
	await get_tree().create_timer(0.2).timeout
	velocity = Vector2.ZERO

func _die() -> void:
	_is_dead = true
	set_physics_process(false)
	died.emit()
	queue_free()

func is_dead() -> bool:
	return _is_dead

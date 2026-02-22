extends CharacterBody2D
class_name Player

signal health_changed(current: int, maximum: int)
signal player_died

@export_group("Movement Settings")
@export var move_speed: float = 200.0
@export var jump_force: float = 350.0
@export var dash_speed: float = 500.0
@export var dash_cooldown: float = 1.0
@export var max_jumps: int = 2

@export_group("Attack Settings")
@export var attack_point: Node2D
@export var attack_range: float = 50.0
@export var attack_damage: float = 1.0
@export var attack_cooldown: float = 0.3

@export_group("Health Settings")
@export var max_health: int = 5
@export var invincibility_duration: float = 1.0
@export var knockback_force: float = 300.0

var _current_health: int
var _current_jumps: int = 0
var _can_dash: bool = true
var _is_dashing: bool = false
var _dash_time: float = 0.0
var _dash_duration: float = 0.2
var _can_attack: bool = true
var _is_invincible: bool = false
var _facing_right: bool = true
var _start_position: Vector2

@onready var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var _sprite: Node2D = $PlayerSprite if has_node("PlayerSprite") else null

func _ready() -> void:
	_current_health = max_health
	_start_position = global_position
	health_changed.emit(_current_health, max_health)
	print("Player ready! Health: ", _current_health)

func _physics_process(delta: float) -> void:
	if _is_dashing:
		_process_dash(delta)
		return
	
	_apply_gravity(delta)
	_handle_input()
	_handle_jump()
	_handle_dash()
	_handle_attack()
	_move()
	_flip_sprite()

func _handle_input() -> void:
	velocity.x = Input.get_axis("move_left", "move_right") * move_speed
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		print("Moving: ", velocity.x)

func _move() -> void:
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		print("Jump pressed! on_floor: ", is_on_floor(), " jumps: ", _current_jumps)
		if is_on_floor():
			_perform_jump()
		elif _current_jumps < max_jumps - 1:
			_perform_jump()
			_current_jumps += 1

func _perform_jump() -> void:
	velocity.y = -jump_force

func _handle_dash() -> void:
	if Input.is_action_just_pressed("dash"):
		print("Dash pressed! can_dash: ", _can_dash, " velocity.x: ", velocity.x)
		if _can_dash and velocity.x != 0:
			_start_dash()

func _start_dash() -> void:
	_can_dash = false
	_is_dashing = true
	_dash_time = _dash_duration

func _process_dash(delta: float) -> void:
	_dash_time -= delta
	if _dash_time <= 0:
		_end_dash()
	else:
		velocity.y = 0
		velocity.x = sign(velocity.x) * dash_speed
		move_and_slide()

func _end_dash() -> void:
	_is_dashing = false
	await get_tree().create_timer(dash_cooldown).timeout
	_can_dash = true

func _handle_attack() -> void:
	if Input.is_action_just_pressed("attack") and _can_attack:
		_perform_attack()

func _perform_attack() -> void:
	_can_attack = false
	_detect_enemies()
	await get_tree().create_timer(attack_cooldown).timeout
	_can_attack = true

func _detect_enemies() -> void:
	if not attack_point:
		return
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = attack_point.global_position
	query.collide_with_areas = true
	query.collision_mask = 4
	
	var results = space_state.intersect_point(query, 10)
	
	for result in results:
		var collider = result["collider"]
		if collider.has_method("take_damage"):
			collider.take_damage(attack_damage)

func _flip_sprite() -> void:
	if velocity.x > 0 and not _facing_right:
		_facing_right = true
		scale.x = -1
	elif velocity.x < 0 and _facing_right:
		_facing_right = false
		scale.x = -1

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
	var direction = sign(velocity.x) if velocity.x != 0 else (1 if _facing_right else -1)
	velocity = Vector2(direction * knockback_force, -knockback_force * 0.3)

func _start_invincibility() -> void:
	_is_invincible = true
	await get_tree().create_timer(invincibility_duration).timeout
	_is_invincible = false

func _die() -> void:
	set_physics_process(false)
	player_died.emit()
	
	await get_tree().create_timer(2.0).timeout
	_respawn()

func _respawn() -> void:
	global_position = _start_position
	_current_health = max_health
	health_changed.emit(_current_health, max_health)
	set_physics_process(true)
	velocity = Vector2.ZERO

func heal(amount: int) -> void:
	_current_health = min(_current_health + amount, max_health)
	health_changed.emit(_current_health, max_health)

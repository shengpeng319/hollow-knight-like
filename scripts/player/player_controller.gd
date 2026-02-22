extends CharacterBody2D

@export_group("Movement Settings")
@export var move_speed: float = 200.0
@export var jump_force: float = 350.0
@export var dash_speed: float = 500.0
@export var dash_cooldown: float = 1.0
@export var max_jumps: int = 2

@export_group("Ground Detection")
@export var ground_check: Node2D
@export var ground_layer: int = 1

var _current_jumps: int = 0
var _can_dash: bool = true
var _is_dashing: bool = false
var _dash_time: float = 0.0
var _dash_duration: float = 0.2
var _facing_right: bool = true

@onready var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	if _is_dashing:
		_process_dash(delta)
		return
	
	_apply_gravity(delta)
	_handle_input()
	_handle_jump()
	_handle_dash()
	_move()
	_flip_sprite()

func _handle_input() -> void:
	velocity.x = Input.get_axis("move_left", "move_right") * move_speed

func _move() -> void:
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		if _is_on_ground():
			_perform_jump()
		elif _current_jumps < max_jumps - 1:
			_perform_jump()
			_current_jumps += 1

func _perform_jump() -> void:
	velocity.y = -jump_force

func _handle_dash() -> void:
	if Input.is_action_just_pressed("dash") and _can_dash and velocity.x != 0:
		_start_dash()

func _start_dash() -> void:
	_can_dash = false
	_is_dashing = true
	_dash_time = _dash_duration
	set_physics_process(false)

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
	set_physics_process(true)
	await get_tree().create_timer(dash_cooldown).timeout
	_can_dash = true

func _is_on_ground() -> bool:
	if ground_check:
		return ground_check.is_colliding()
	return is_on_floor()

func _flip_sprite() -> void:
	if velocity.x > 0 and not _facing_right:
		_facing_right = true
		scale.x = -1
	elif velocity.x < 0 and _facing_right:
		_facing_right = false
		scale.x = -1

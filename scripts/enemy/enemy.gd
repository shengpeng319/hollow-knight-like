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
var _health_bar: ProgressBar
var _health_bar_bg: ColorRect
var _facing_right: bool = true

@onready var _sprite: Node = $EnemySprite if has_node("EnemySprite") else null
@onready var _attack_area: Area2D = $AttackArea if has_node("AttackArea") else null
@onready var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	_current_health = max_health
	_start_position = global_position
	_patrol_direction = 1 if randf() > 0.5 else -1
	
	_create_health_bar()
	
	if _attack_area:
		_attack_area.body_entered.connect(_on_attack_area_body_entered)
	
	print("Enemy ready! Health: ", _current_health, " Speed: ", move_speed)

func _create_health_bar() -> void:
	_health_bar_bg = ColorRect.new()
	_health_bar_bg.color = Color(0.2, 0.2, 0.2, 1)
	_health_bar_bg.custom_minimum_size = Vector2(40, 6)
	_health_bar_bg.position = Vector2(-20, -35)
	add_child(_health_bar_bg)
	
	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(38, 4)
	_health_bar.position = Vector2(-19, -34)
	_health_bar.max_value = max_health
	_health_bar.value = _current_health
	_health_bar.show_percentage = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 0.3, 0.3, 1)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	_health_bar.add_theme_stylebox_override("fill", style)
	
	add_child(_health_bar)

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
	velocity.y += _gravity * 0.016
	
	if _patrol_direction > 0:
		_facing_right = true
	else:
		_facing_right = false
	
	if global_position.x > _start_position.x + patrol_distance:
		_patrol_direction = -1
	elif global_position.x < _start_position.x - patrol_distance:
		_patrol_direction = 1
	
	move_and_slide()

func _chase_player(distance_to_player: float) -> void:
	var direction = sign(_player.global_position.x - global_position.x)
	velocity.x = direction * move_speed * 1.5
	velocity.y += _gravity * 0.016
	
	if direction > 0:
		_facing_right = true
	else:
		_facing_right = false
	
	if distance_to_player <= attack_distance:
		_attack()
	
	move_and_slide()

func _attack() -> void:
	if not _can_attack:
		return
	
	_can_attack = false
	
	_show_attack_hitbox()
	_detect_player()
	
	await get_tree().create_timer(attack_cooldown).timeout
	_can_attack = true

func _show_attack_hitbox() -> void:
	if _sprite:
		var hitbox = ColorRect.new()
		hitbox.color = Color(1, 0, 0, 0.5)
		hitbox.size = Vector2(attack_range, 30)
		hitbox.position = Vector2(0, -15)
		_sprite.add_child(hitbox)
		await get_tree().create_timer(0.15).timeout
		hitbox.queue_free()

func _detect_player() -> void:
	if not _player:
		return
	
	var direction = 1 if _facing_right else -1
	var attack_pos = global_position + Vector2(direction * 30, 0)
	var distance = attack_pos.distance_to(_player.global_position)
	print("Enemy checking player distance: ", distance, " attack_range: ", attack_range, " facing: ", _facing_right)
	
	if distance <= attack_range:
		print("Enemy attacking player!")
		_player.take_damage(attack_damage)

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and _can_attack:
		print("Enemy attacking player!")
		_attack()

func take_damage(damage: float) -> void:
	if _is_dead:
		return
	
	_current_health -= int(damage)
	_current_health = max(0, _current_health)
	print("Enemy took damage! Health: ", _current_health)
	
	if _health_bar:
		_health_bar.value = _current_health
	
	if _sprite:
		var original_color = Color(1, 0.3, 0.3, 1)
		_sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		_sprite.modulate = original_color
	
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
	
	if _health_bar:
		_health_bar.queue_free()
	if _health_bar_bg:
		_health_bar_bg.queue_free()
	
	_explode_effect()
	
	died.emit()
	queue_free()

func _explode_effect() -> void:
	if _sprite:
		_sprite.modulate = Color(1, 0.5, 0.5, 1)
		var tween = create_tween()
		tween.tween_property(_sprite, "scale", Vector2(1.5, 1.5), 0.1)
		tween.tween_property(_sprite, "modulate:a", 0.0, 0.15)

func is_dead() -> bool:
	return _is_dead

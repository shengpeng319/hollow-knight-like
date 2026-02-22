extends Node2D
class_name PlayerAttack

@export_group("Attack Settings")
@export var attack_point: Node2D
@export var attack_range: float = 50.0
@export var attack_damage: float = 1.0
@export var attack_cooldown: float = 0.3
@export var enemy_layer: int = 3

var _can_attack: bool = true
var _owner_character: CharacterBody2D

func _ready() -> void:
	_owner_character = get_parent() as CharacterBody2D

func _process(_delta: float) -> void:
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
	query.collision_mask = enemy_layer
	
	var results = space_state.intersect_point(query, 10)
	
	for result in results:
		var collider = result["collider"]
		if collider.has_method("take_damage"):
			collider.take_damage(attack_damage)

func _draw() -> void:
	if attack_point:
		draw_circle(attack_point.position, attack_range, Color(1, 0, 0, 0.3))

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

# Attack animation
@export_group("Animation Settings")
@export var attack_animation_speed: float = 0.15
@export var slash_arc_degrees: float = 120.0
@export var slash_width: float = 8.0
@export var slash_length: float = 40.0
@export var slash_color: Color = Color(0.9, 0.95, 1.0, 1.0)
@export var enable_particles: bool = true
@export var particle_count: int = 8

var _current_health: int
var _current_jumps: int = 0
var _can_dash: bool = true
var _is_dashing: bool = false
var _dash_time: float = 0.0
var _dash_duration: float = 0.2
var _can_attack: bool = true
var _is_attacking: bool = false
var _is_invincible: bool = false
var _facing_right: bool = true
var _start_position: Vector2
var _current_attack_dir: int = 0

var _slash_sprite: Sprite2D = null
var _slash_particles: GPUParticles2D = null

var _combo_count: int = 0
var _combo_timer: float = 0.0
var _combo_window: float = 0.5
var _max_combo: int = 4

@onready var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var _sprite: Node = $PlayerSprite if has_node("PlayerSprite") else null
@onready var _attack_area: Area2D = $AttackArea if has_node("AttackArea") else null

func _ready() -> void:
	_current_health = max_health
	_start_position = global_position
	health_changed.emit(_current_health, max_health)
	print("Player ready! Health: ", _current_health)

func _physics_process(delta: float) -> void:
	if _is_dashing:
		_process_dash(delta)
		return
	
	_update_combo_timer(delta)
	_apply_gravity(delta)
	_handle_input()
	_handle_jump()
	_handle_dash()
	_handle_attack()
	_move()
	_flip_sprite()

func _update_combo_timer(delta: float) -> void:
	if _combo_timer > 0:
		_combo_timer -= delta
		if _combo_timer <= 0:
			_combo_count = 0

func _handle_input() -> void:
	velocity.x = Input.get_axis("move_left", "move_right") * move_speed

func _move() -> void:
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta
	else:
		if _current_jumps > 0:
			_current_jumps = 0

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			_perform_jump()
		elif _current_jumps < max_jumps - 1:
			_perform_jump()
			_current_jumps += 1

func _perform_jump() -> void:
	velocity.y = -jump_force

func _handle_dash() -> void:
	if Input.is_action_just_pressed("dash"):
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
	if Input.is_action_just_pressed("attack"):
		if _can_attack and not _is_attacking:
			_perform_attack()

func _perform_attack() -> void:
	_can_attack = false
	_is_attacking = true
	
	_combo_count = (_combo_count + 1) % (_max_combo + 1)
	_combo_timer = _combo_window
	
	_current_attack_dir = 0
	if Input.is_action_pressed("move_up"):
		_current_attack_dir = 1
	elif Input.is_action_pressed("move_down"):
		_current_attack_dir = -1
	
	print("Attack! Combo: ", _combo_count, " Direction: ", _current_attack_dir, " facing: ", _facing_right)
	
	_modulate_for_combo()
	_create_slash_effect()
	_detect_enemies()
	
	await get_tree().create_timer(attack_animation_speed).timeout
	
	_reset_sprite()
	
	await get_tree().create_timer(attack_cooldown).timeout
	_can_attack = true
	_is_attacking = false

func _modulate_for_combo() -> void:
	if not _sprite:
		return
	
	var combo_colors = [
		Color(1, 1, 1, 1),
		Color(1, 0.9, 0.7, 1),
		Color(1, 0.8, 0.5, 1),
		Color(1, 0.6, 0.3, 1),
		Color(1, 0.4, 0.2, 1)
	]
	_sprite.modulate = combo_colors[_combo_count]

func _reset_sprite() -> void:
	if _sprite:
		_sprite.modulate = Color(0.2, 0.6, 1, 1)

func _create_slash_effect() -> void:
	if _slash_sprite and is_instance_valid(_slash_sprite):
		_slash_sprite.queue_free()
		await get_tree().process_frame
	
	_slash_sprite = Sprite2D.new()
	_slash_sprite.texture = _generate_arc_slash_texture()
	_slash_sprite.modulate = slash_color
	
	var offset = Vector2.ZERO
	var rotation = 0.0
	
	match _current_attack_dir:
		0:
			offset = Vector2(25 * (1 if _facing_right else -1), 0)
			rotation = 0.0 if _facing_right else deg_to_rad(180)
		1:
			offset = Vector2(0, -25)
			rotation = deg_to_rad(-90)
		-1:
			offset = Vector2(0, 25)
			rotation = deg_to_rad(90)
	
	_slash_sprite.position = offset
	_slash_sprite.rotation = rotation
	_slash_sprite.z_index = 10
	add_child(_slash_sprite)
	
	_animate_slash_arc()
	_create_particles()
	_trigger_screen_shake()

func _generate_arc_slash_texture() -> ImageTexture:
	var img_width = int(slash_length * 1.5)
	var img_height = int(slash_width * 3)
	var img = Image.create(img_width, img_height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var center_y = img_height / 2.0
	var thickness = slash_width
	
	for x in range(img_width):
		var progress = float(x) / float(img_width)
		var angle = -slash_arc_degrees / 2.0 + slash_arc_degrees * progress
		var dist_from_center = abs(sin(progress * PI)) * thickness
		
		for y in range(img_height):
			var dist = abs(y - center_y)
			if dist < dist_from_center:
				var alpha = 1.0 - (dist / dist_from_center)
				alpha *= 1.0 - pow(abs(progress - 0.5) * 2, 2)
				var col = slash_color
				col.a = alpha * 0.9
				img.set_pixel(x, y, col)
	
	return ImageTexture.create_from_image(img)

func _animate_slash_arc() -> void:
	var tween = create_tween()
	var start_rot = _slash_sprite.rotation
	var arc_amount = deg_to_rad(slash_arc_degrees * 0.3)
	
	match _current_attack_dir:
		0:
			tween.tween_property(_slash_sprite, "rotation", start_rot + arc_amount * (1 if _facing_right else -1), attack_animation_speed * 0.3)
		1:
			tween.tween_property(_slash_sprite, "rotation", start_rot + arc_amount, attack_animation_speed * 0.3)
		-1:
			tween.tween_property(_slash_sprite, "rotation", start_rot - arc_amount, attack_animation_speed * 0.3)
	
	tween.parallel().tween_property(_slash_sprite, "modulate:a", 0.0, attack_animation_speed)
	tween.tween_callback(_clear_slash_sprite)

func _create_particles() -> void:
	if not enable_particles:
		return
	
	if _slash_particles and is_instance_valid(_slash_particles):
		_slash_particles.queue_free()
	
	_slash_particles = GPUParticles2D.new()
	_slash_particles.amount = particle_count
	_slash_particles.lifetime = 0.3
	_slash_particles.explosiveness = 1.0
	_slash_particles.one_shot = true
	_slash_particles.emitting = true
	
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 10.0
	particle_material.direction = Vector3(1, 0, 0) if _current_attack_dir == 0 else Vector3(0, -1 if _current_attack_dir == 1 else 1, 0)
	particle_material.spread = 60.0
	particle_material.initial_velocity_min = 50.0
	particle_material.initial_velocity_max = 150.0
	particle_material.gravity = Vector3(0, 200, 0)
	particle_material.scale_min = 2.0
	particle_material.scale_max = 4.0
	
	var grad = Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(0.8, 0.9, 1, 0))
	particle_material.color_ramp = grad
	
	_slash_particles.process_material = particle_material
	
	var particle_texture = _create_particle_texture()
	_slash_particles.texture = particle_texture
	
	match _current_attack_dir:
		0:
			_slash_particles.position = Vector2(30 * (1 if _facing_right else -1), 0)
		1:
			_slash_particles.position = Vector2(0, -30)
		-1:
			_slash_particles.position = Vector2(0, 30)
	
	_slash_particles.z_index = 9
	add_child(_slash_particles)
	
	await get_tree().create_timer(0.35).timeout
	if _slash_particles and is_instance_valid(_slash_particles):
		_slash_particles.queue_free()
		_slash_particles = null

func _create_particle_texture() -> ImageTexture:
	var size = 8
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x - size/2.0, y - size/2.0).length()
			if dist < size / 2.0:
				var alpha = 1.0 - (dist / (size / 2.0))
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	return ImageTexture.create_from_image(img)

func _trigger_screen_shake() -> void:
	var camera = get_viewport().get_camera_2d()
	if camera:
		var original_offset = camera.offset
		var tween = create_tween()
		for i in range(3):
			var shake_offset = Vector2(randf_range(-3, 3), randf_range(-3, 3))
			tween.tween_property(camera, "offset", original_offset + shake_offset, 0.03)
		tween.tween_property(camera, "offset", original_offset, 0.05)

func _clear_slash_sprite() -> void:
	if _slash_sprite and is_instance_valid(_slash_sprite):
		_slash_sprite.queue_free()
	_slash_sprite = null

func _detect_enemies() -> void:
	var direction = 1 if _facing_right else -1
	var attack_offset = Vector2.ZERO
	var attack_shape = RectangleShape2D.new()
	
	match _current_attack_dir:
		0:  # Horizontal
			attack_offset = Vector2(direction * 30, 0)
			attack_shape.size = Vector2(35, 10)
		1:  # Up
			attack_offset = Vector2(0, -30)
			attack_shape.size = Vector2(10, 35)
		-1:  # Down
			attack_offset = Vector2(0, 30)
			attack_shape.size = Vector2(10, 35)
	
	# Update attack area position and shape
	if _attack_area:
		_attack_area.global_position = global_position + attack_offset
		
		# Update collision shape
		var collision_shape = _attack_area.get_node_or_null("CollisionShape2D")
		if collision_shape:
			collision_shape.shape = attack_shape
		
		# Get overlapping bodies
		var bodies = _attack_area.get_overlapping_bodies()
		print("Attack detected ", bodies.size(), " bodies in direction ", _current_attack_dir)
		
		for body in bodies:
			print("Hit: ", body.name)
			if body.has_method("take_damage"):
				body.take_damage(attack_damage)

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
	
	print("Player took damage! Health: ", _current_health)
	
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
	# Flash effect
	if _sprite:
		var tween = create_tween()
		for i in range(5):
			tween.tween_property(_sprite, "modulate:a", 0.3, 0.1)
			tween.tween_property(_sprite, "modulate:a", 1.0, 0.1)
	
	await get_tree().create_timer(invincibility_duration).timeout
	_is_invincible = false
	if _sprite:
		_sprite.modulate.a = 1.0

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

func get_max_health() -> int:
	return max_health

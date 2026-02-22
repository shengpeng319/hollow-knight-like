extends Area2D

@export var ground_layer: int = 1

func is_colliding() -> bool:
	var overlapping = get_overlapping_bodies()
	for body in overlapping:
		if body.collision_layer & (1 << (ground_layer - 1)):
			return true
	return false

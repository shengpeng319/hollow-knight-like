extends Node2D

func _ready():
	# Create a simple sword slash effect
	var texture = _create_sword_texture()
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.modulate = Color(1, 1, 1, 0.8)
	add_child(sprite)
	
	# Animate the sprite
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

func _create_sword_texture() -> ImageTexture:
	var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# Draw a white arc
	for i in range(60):
		var angle = deg_to_rad(90 + i * 1.5)
		var inner_r = 20
		var outer_r = 50
		for r in range(inner_r, outer_r):
			var x = 64 + int(cos(angle) * r)
			var y = 64 + int(sin(angle) * r)
			if x >= 0 and x < 128 and y >= 0 and y < 128:
				img.set_pixel(x, y, Color.WHITE)
	
	return ImageTexture.create_from_image(img)

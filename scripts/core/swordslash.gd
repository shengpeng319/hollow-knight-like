extends Sprite2D

var _lifetime: float = 0.15

func _ready():
	modulate = Color(1, 1, 1, 0.8)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, _lifetime)
	tween.tween_callback(queue_free)

func setup(pos: Vector2, facing_right: bool, range_val: float) -> void:
	global_position = pos
	if not facing_right:
		scale.x = -1
	
	var img = Image.create(int(range_val * 2), 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	for i in range(40):
		var angle = deg_to_rad(90 + i * 2.25)
		var r = int(20 + i * 0.5)
		var cx = int(range_val)
		var cy = 32
		var x = cx + int(cos(angle) * r)
		var y = cy + int(sin(angle) * r)
		if x >= 0 and x < int(range_val * 2) and y >= 0 and y < 64:
			img.set_pixel(x, y, Color(1, 1, 1, 0.8))
	
	texture = ImageTexture.create_from_image(img)

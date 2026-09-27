class_name ParallaxLayers
extends Node2D
## Builds parallax background (and foreground) layers from a level's environment art.
##
## Each image repeats horizontally, so it should tile seamlessly left-to-right.
## Its bottom edge lines up with the bottom of the screen when the camera is at the
## lowest point of the level; above an image's top edge the clear colour shows.

## Draw order: backgrounds behind the level tiles, foregrounds in front of the hero.
const BACKGROUND_Z := -100
const FOREGROUND_Z := 100


func build(art_dir: String, layers: Dictionary, level_bounds: Rect2) -> void:
	var screen := get_viewport_rect().size
	# Camera top edge when it sits at the bottom of the level.
	var lowest_camera_top := level_bounds.end.y - screen.y
	var index := 0
	for layer_name: String in layers:
		var path := art_dir + layer_name + ".png"
		if not ResourceLoader.exists(path):
			continue
		var texture: Texture2D = load(path)
		var factor: float = layers[layer_name]
		var size := texture.get_size()

		var parallax := Parallax2D.new()
		parallax.name = layer_name
		parallax.scroll_scale = Vector2(factor, factor)
		parallax.scroll_offset = Vector2(0.0, screen.y - size.y + lowest_camera_top * factor)
		parallax.repeat_size = Vector2(size.x, 0.0)
		parallax.repeat_times = ceili(screen.x / size.x) + 1
		parallax.z_index = (FOREGROUND_Z if factor > 1.0 else BACKGROUND_Z) + index

		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		parallax.add_child(sprite)
		add_child(parallax)
		index += 1

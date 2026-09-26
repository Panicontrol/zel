extends Node2D
## Root of the game scene: loads the level and frames it with the camera.

@onready var level: Level = $Level
@onready var camera: Camera2D = $Camera


func _ready() -> void:
	var bounds := level.get_bounds()
	camera.position = bounds.get_center()
	print("Level loaded: %d x %d px" % [bounds.size.x, bounds.size.y])

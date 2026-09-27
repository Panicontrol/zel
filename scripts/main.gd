extends Node2D
## Root of the game scene: loads the level and its parallax art, spawns the hero
## and follows them with the camera.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const LEVEL_DATA := preload("res://levels/level_01.gd")
## Keeps the hero a little below the screen centre so more of what's ahead is visible.
const CAMERA_OFFSET := Vector2(0.0, -80.0)

var player: Player

@onready var level: Level = $Level
@onready var camera: Camera2D = $Camera
@onready var parallax: ParallaxLayers = $Parallax


func _ready() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = level.player_spawn
	add_child(player)

	var bounds := level.get_bounds()
	parallax.build(LEVEL_DATA.ART_DIR, LEVEL_DATA.PARALLAX, bounds)
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	camera.global_position = player.global_position + CAMERA_OFFSET
	camera.reset_smoothing()


func _process(_delta: float) -> void:
	camera.global_position = player.global_position + CAMERA_OFFSET

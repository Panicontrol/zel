class_name Player
extends CharacterBody2D
## The hero: run, jump and frame-by-frame sprite animation.
## The node origin is at the feet.
##
## Animations are horizontal strips of square frames in res://assets/hero/:
## idle.png, walk.png, jump.png, fall.png. The frame count is width / height,
## so a strip from ComfyUI with any number of frames drops straight in.

const ANIMATIONS := {
	"idle": {"fps": 6.0, "loop": true},
	"walk": {"fps": 12.0, "loop": true},
	"jump": {"fps": 1.0, "loop": false},
	"fall": {"fps": 1.0, "loop": false},
}
const ANIMATION_DIR := "res://assets/hero/"

# Distances are in 1080p screen pixels; a tile is 64 px.
const RUN_SPEED := 400.0
const GROUND_ACCEL := 3600.0
const GROUND_DECEL := 4400.0
const AIR_ACCEL := 2400.0
const GRAVITY := 3000.0
const FALL_GRAVITY_MULT := 1.5
const MAX_FALL_SPEED := 1700.0
const JUMP_VELOCITY := -1120.0
## Releasing jump early cuts the rise, so a tap is a short hop.
const JUMP_CUT := 0.45
## Jump still works this long after walking off a ledge.
const COYOTE_TIME := 0.1
## A jump pressed this long before landing still fires.
const JUMP_BUFFER := 0.12

var facing := 1

var _coyote := 0.0
var _jump_buffer := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	sprite.sprite_frames = _load_sprite_frames()
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	_jump_buffer = JUMP_BUFFER if Input.is_action_just_pressed("jump") else maxf(0.0, _jump_buffer - delta)
	if is_on_floor():
		_coyote = COYOTE_TIME
	else:
		_coyote -= delta

	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
	var accel := AIR_ACCEL
	if is_on_floor():
		accel = GROUND_ACCEL if dir != 0.0 else GROUND_DECEL
	velocity.x = move_toward(velocity.x, dir * RUN_SPEED, accel * delta)

	var gravity := GRAVITY * (FALL_GRAVITY_MULT if velocity.y > 0.0 else 1.0)
	velocity.y = minf(velocity.y + gravity * delta, MAX_FALL_SPEED)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer = 0.0
		_coyote = 0.0

	move_and_slide()
	_update_animation()


func _update_animation() -> void:
	sprite.flip_h = facing < 0
	var anim := "idle"
	sprite.speed_scale = 1.0
	if not is_on_floor():
		anim = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 20.0:
		anim = "walk"
		# Feet keep pace with the ground while speeding up or slowing down.
		sprite.speed_scale = clampf(absf(velocity.x) / RUN_SPEED, 0.4, 1.0)
	if sprite.animation != anim:
		sprite.play(anim)


func _load_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim_name: String in ANIMATIONS:
		var sheet: Texture2D = load(ANIMATION_DIR + anim_name + ".png")
		var size := sheet.get_height()
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, ANIMATIONS[anim_name].fps)
		frames.set_animation_loop(anim_name, ANIMATIONS[anim_name].loop)
		for i in sheet.get_width() / size:
			var frame := AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(i * size, 0, size, size)
			frames.add_frame(anim_name, frame)
	return frames

class_name Player
extends CharacterBody2D
## The hero. Walking works like Prince of Persia: it is made of whole steps.
## A tap makes exactly one step, holding chains steps, and a released key lets the
## current step finish before stopping. Tapping the other way only turns around.
##
## Movement on the ground is driven by the animation ("root motion"): each walk frame
## moves the hero by its own number of pixels, so the feet stay planted.
## The node origin is at the feet.
##
## Animations are horizontal strips of square frames in res://assets/hero/:
## idle.png, walk.png, jump.png, fall.png. The frame count is width / height,
## so a strip from ComfyUI with any number of frames drops straight in.

const ANIMATIONS := {
	"idle": {"fps": 6.0, "loop": true},
	# Two steps per cycle. "dx" is how far each frame moves the hero, in px;
	# half the cycle is one step (see step_length()). Tune it to where the feet land in the art.
	"walk": {"fps": 8.0, "loop": true, "dx": [12, 12, 12, 12, 12, 12, 12, 12]},
	"jump": {"fps": 1.0, "loop": false},
	"fall": {"fps": 1.0, "loop": false},
}
const ANIMATION_DIR := "res://assets/hero/"

enum State { IDLE, WALK, AIR }

# Distances are in 1080p screen pixels; a tile is 64 px and ~63 px is one metre.
## Holding the opposite direction longer than this turns and then walks;
## a shorter tap only turns around.
const TURN_TIME := 0.15
## Horizontal speed you can steer to while in the air.
const AIR_SPEED := 200.0
const AIR_ACCEL := 1200.0
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

var state := State.IDLE
var facing := 1

var _coyote := 0.0
var _jump_buffer := 0.0
var _turn_lock := 0.0
## Current walk frame; kept between steps so the feet alternate.
var _walk_frame := 0
var _frame_clock := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	sprite.sprite_frames = _load_sprite_frames()
	sprite.play("idle")


## Length of one step in px: the sum of "dx" over half the walk cycle.
static func step_length() -> float:
	var dx: Array = ANIMATIONS.walk.dx
	var total := 0.0
	for i in dx.size() / 2:
		total += dx[i]
	return total


func _physics_process(delta: float) -> void:
	_jump_buffer = JUMP_BUFFER if Input.is_action_just_pressed("jump") else maxf(0.0, _jump_buffer - delta)
	_turn_lock = maxf(0.0, _turn_lock - delta)
	if is_on_floor():
		_coyote = COYOTE_TIME
	else:
		_coyote -= delta

	var input_dir := int(signf(Input.get_axis("move_left", "move_right")))
	match state:
		State.IDLE:
			velocity.x = 0.0
			if input_dir != 0:
				if input_dir != facing:
					facing = input_dir
					_turn_lock = TURN_TIME
				elif _turn_lock <= 0.0 and not test_move(global_transform, Vector2(facing * 2.0, 0.0)):
					state = State.WALK
					_frame_clock = 0.0
		State.WALK:
			_walk(delta, input_dir)
		State.AIR:
			if input_dir != 0:
				facing = input_dir
			velocity.x = move_toward(velocity.x, input_dir * AIR_SPEED, AIR_ACCEL * delta)

	var gravity := GRAVITY * (FALL_GRAVITY_MULT if velocity.y > 0.0 else 1.0)
	velocity.y = minf(velocity.y + gravity * delta, MAX_FALL_SPEED)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer = 0.0
		_coyote = 0.0
		state = State.AIR

	move_and_slide()

	if state == State.AIR and is_on_floor() and velocity.y >= 0.0:
		state = State.IDLE
		velocity.x = 0.0
	elif state != State.AIR and not is_on_floor():
		state = State.AIR  # walked off a ledge; keeps the walking speed
	elif state == State.WALK and is_on_wall():
		state = State.IDLE
	_update_animation()


## Plays the walk cycle and moves the hero by each frame's "dx".
## A step ends every half cycle; the hero stops there unless the key is still held.
func _walk(delta: float, input_dir: int) -> void:
	var walk: Dictionary = ANIMATIONS.walk
	var dx: Array = walk.dx
	var frame_time := 1.0 / float(walk.fps)
	# Each frame's distance is spread evenly over the time the frame is on screen.
	# A physics tick can straddle a frame change, so it is split at the boundary;
	# that keeps every step exactly step_length() long.
	var distance := 0.0
	var time_left := delta
	while time_left > 0.0:
		var t := minf(time_left, frame_time - _frame_clock)
		distance += float(dx[_walk_frame]) * t / frame_time
		_frame_clock += t
		time_left -= t
		if _frame_clock < frame_time - 0.00001:
			break
		_frame_clock = 0.0
		_walk_frame = (_walk_frame + 1) % dx.size()
		var step_finished := _walk_frame % (dx.size() / 2) == 0
		if step_finished and input_dir != facing:
			state = State.IDLE
			break
	velocity.x = facing * distance / delta


func _update_animation() -> void:
	sprite.flip_h = facing < 0
	if state == State.WALK:
		# Walk frames are stepped by _walk(), in sync with the movement.
		if sprite.animation != "walk" or sprite.is_playing():
			sprite.stop()
			sprite.animation = "walk"
		sprite.frame = _walk_frame
		return
	var anim := "idle"
	if state == State.AIR:
		anim = "jump" if velocity.y < 0.0 else "fall"
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func _load_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim_name: String in ANIMATIONS:
		var sheet: Texture2D = load(ANIMATION_DIR + anim_name + ".png")
		var size := sheet.get_height()
		var count := sheet.get_width() / size
		if ANIMATIONS[anim_name].has("dx"):
			assert(ANIMATIONS[anim_name].dx.size() == count,
				"%s.png has %d frames but ANIMATIONS.%s.dx lists %d" % [anim_name, count, anim_name, ANIMATIONS[anim_name].dx.size()])
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, ANIMATIONS[anim_name].fps)
		frames.set_animation_loop(anim_name, ANIMATIONS[anim_name].loop)
		for i in count:
			var frame := AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(i * size, 0, size, size)
			frames.add_frame(anim_name, frame)
	return frames

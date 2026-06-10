extends CharacterBody2D

# Movement tuning
@export var acceleration := 1500.0  # Ground acceleration rate
@export var air_acceleration := 800.0  # Air acceleration rate
@export var coyote_time := 0.15  # Grace period for jumping after leaving floor
@export var friction := 1800.0  # Deceleration rate on ground
@export var jump_buffer_time := 0.15  # Grace period for buffered jump input
@export var jump_velocity := -500.0  # Initial upward velocity for jump
@export var speed := 300.0  # Maximum horizontal movement speed
@export var fall_death_threshold := 1000.0  # Y position where player resets
@export var reset_delay := 2.0  # Delay before resetting after falling

var coyote_timer = 0.0  # Countdown timer for coyote window
var fall_timer = 0.0  # Countdown timer for fall reset
var jump_buffer_timer = 0.0  # Countdown timer for jump buffer window
var spawn_position: Vector2  # Player's starting position


func _ready() -> void:
	spawn_position = position

func _physics_process(delta: float) -> void:
	# Buffer jump input for a short window
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	coyote_timer -= delta
	jump_buffer_timer -= delta
	
	# Reset coyote timer when grounded, otherwise apply gravity
	if is_on_floor():
		coyote_timer = coyote_time
	
	else:
		velocity += get_gravity() * delta

	# Perform jump if buffered input is available and within coyote window
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0
		coyote_timer = 0

	# Cut jump short if player releases jump while ascending
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	# Handle horizontal movement
	var direction = Input.get_axis(
		"move_left",
		"move_right"
	)

	if direction:
		velocity.x = move_toward(
			velocity.x,
			direction * speed,
			(acceleration if is_on_floor() else air_acceleration) * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0,
			friction * delta
		)

	# Apply velocity and handle collisions
	move_and_slide()

	# Detect falling off and reset after delay
	if position.y > fall_death_threshold:
		fall_timer += delta
		if fall_timer >= reset_delay:
			position = spawn_position
			velocity = Vector2.ZERO
			fall_timer = 0.0
	elif fall_timer > 0:
		fall_timer = 0.0

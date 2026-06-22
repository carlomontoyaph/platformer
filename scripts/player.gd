extends CharacterBody2D

# -------------------------------------------------------------------------- #
# Movement tuning
# -------------------------------------------------------------------------- #

# Horizontal movement
@export var speed := 300.0  # Maximum horizontal movement speed
@export var acceleration := 1500.0  # Ground acceleration rate
@export var air_acceleration := 800.0  # Air acceleration rate
@export var friction := 1800.0  # Deceleration rate on ground

# Jump
@export var jump_velocity := -500.0  # Initial upward velocity for jump
@export var jump_cut_multiplier := 0.5  # Velocity multiplier when jump is released early
@export var coyote_time := 0.15  # Grace period for jumping after leaving floor
@export var jump_buffer_time := 0.15  # Grace period for buffered jump input

# Dash
@export var dash_speed := 650
@export var dash_duration := 0.15

# Wall slide / wall jump
@export var wall_slide_speed := 120  # Max downward speed while sliding on a wall
@export var wall_jump_push := 350.0  # Horizontal force applied away from wall on wall-jump
@export var wall_jump_lock_time := 0.12  # Seconds to lock horizontal input after wall-jump

# Fall reset
@export var fall_death_y := 1000.0  # Y position where player resets
@export var fall_reset_delay := 2.0  # Delay before resetting after falling

# -------------------------------------------------------------------------- #
# Player state
# -------------------------------------------------------------------------- #

# Animation state
enum PlayerState { IDLE, RUN, JUMP, FALL }
var current_state := PlayerState.IDLE

# Position
var spawn_position: Vector2  # Respawn position

# Jump state
var can_double_jump := false
var coyote_timer := 0.0  # Countdown for coyote window
var jump_buffer_timer := 0.0  # Countdown for jump buffer window

# Dash state
var can_dash := true
var is_dashing := false
var dash_direction := 1
var dash_timer := 0.0

# Wall state
var is_wall_sliding := false  # True when on wall, airborne, and falling
var wall_jump_lock_timer := 0.0  # Countdown for wall-jump input lock

# Floor detection
var was_on_floor := false  # Tracks floor state for landing detection

# Fall reset
var fall_timer := 0.0  # Countup for fall reset delay

signal landed  # Emitted when player lands on ground


# Finds spawn point or falls back to current position, registers in "player" group.
func _ready() -> void:
	var spawn_point = get_node_or_null("SpawnPoint")
	spawn_position = spawn_point.global_position if spawn_point else position
	add_to_group("player")


# Main physics tick: runs input, timers, state detection, movement, and post-move updates.
func _physics_process(delta: float) -> void:
	# Input
	if Input.is_action_just_pressed('dash'):
		_start_dash()
	_buffer_jump_input()

	# Timers
	_update_timers(delta)

	# State detection (order matters: gravity before wall/jump so caps and overrides apply correctly)
	_apply_gravity(delta)
	_update_ground_state()
	_update_wall_state()

	# Movement
	_handle_wall_slide()
	_handle_jump()
	_handle_horizontal_movement(delta)
	_update_dash(delta)

	# Apply physics
	move_and_slide()

	# Post-move
	_update_state()
	_check_fall_reset(delta)


# Stores jump input in a short buffer window so players
# can press jump slightly before landing and still jump.
func _buffer_jump_input() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time


# Decrements coyote, jump-buffer, and wall-jump-lock timers each frame.
func _update_timers(delta: float) -> void:
	coyote_timer -= delta
	jump_buffer_timer -= delta

	if wall_jump_lock_timer > 0:
		wall_jump_lock_timer -= delta


# Applies gravity when airborne (skipped during dash to preserve horizontal momentum).
func _apply_gravity(delta: float) -> void:
	if not is_on_floor() and not is_dashing:
		velocity += get_gravity() * delta


# Resets coyote timer, jump/dash flags on ground; tracks landing transitions.
func _update_ground_state() -> void:
	if is_on_floor():
		coyote_timer = coyote_time
		can_double_jump = false
		can_dash = true
		if not was_on_floor:
			emit_signal("landed")
			was_on_floor = true
	else:
		was_on_floor = false


# Jump priority:
# 1. Wall jump — bounces off wall with horizontal push
# 2. Coyote + buffer jump — ground jump with a brief forgiveness window
# 3. Double jump — mid-air second jump
# 4. Variable height — cutting velocity short on jump release
func _handle_jump() -> void:
	if _perform_wall_jump():
		return

	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0
		coyote_timer = 0
		can_double_jump = true
	elif Input.is_action_just_pressed("jump") and can_double_jump and not is_on_floor():
		velocity.y = jump_velocity
		can_double_jump = false

	# Variable jump height: release early to cut ascent short
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= jump_cut_multiplier


# Applies left/right input to velocity, with separate ground/air acceleration
# and friction when no direction is held.
func _handle_horizontal_movement(delta: float) -> void:
	if is_dashing:
		return

	if wall_jump_lock_timer > 0:
		return

	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = move_toward(
			velocity.x,
			direction * speed,
			(acceleration if is_on_floor() else air_acceleration) * delta
		)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)


# Updates the animation state enum based on current physics state.
func _update_state() -> void:
	var new_state: PlayerState
	if not is_on_floor():
		new_state = PlayerState.JUMP if velocity.y < 0 else PlayerState.FALL
	elif abs(velocity.x) > 10.0:
		new_state = PlayerState.RUN
	else:
		new_state = PlayerState.IDLE
	current_state = new_state


# After falling below fall_death_y, waits fall_reset_delay seconds then respawns.
func _check_fall_reset(delta: float) -> void:
	if position.y > fall_death_y:
		fall_timer += delta
		if fall_timer >= fall_reset_delay:
			_reset_to_spawn()
	elif fall_timer > 0:
		fall_timer = 0.0


# Teleports player to spawn, zeroes velocity, and clears all timers and jump state.
func _reset_to_spawn() -> void:
	position = spawn_position
	velocity = Vector2.ZERO
	fall_timer = 0.0
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	can_double_jump = false
	can_dash = true
	is_dashing = false
	dash_timer = 0.0
	was_on_floor = false


# Sets is_wall_sliding when on a wall, airborne, and moving downward.
func _update_wall_state() -> void:
	is_wall_sliding = is_on_wall() and not is_on_floor() and velocity.y > 0


# Caps downward velocity to wall_slide_speed while sliding.
func _handle_wall_slide() -> void:
	if is_wall_sliding:
		velocity.y = min(velocity.y, wall_slide_speed)


# Returns true and applies wall-jump velocity if sliding on a wall and jump is pressed.
func _perform_wall_jump() -> bool:
	if not is_wall_sliding:
		return false
	if not Input.is_action_just_pressed("jump"):
		return false

	var wall_direction := get_wall_normal().x

	velocity.x = wall_direction * wall_jump_push
	velocity.y = jump_velocity

	can_double_jump = true

	wall_jump_lock_timer = wall_jump_lock_time

	return true


func _start_dash() -> void:
	if not can_dash:
		return

	if is_dashing:
		return

	dash_direction = sign(Input.get_axis("move_left", "move_right"))

	if dash_direction == 0:
		dash_direction = sign(velocity.x)

	if dash_direction == 0:
		dash_direction = 1

	is_dashing = true
	can_dash = false

	dash_timer = dash_duration

	velocity.y = 0


func _update_dash(delta: float) -> void:
	if not is_dashing:
		return

	dash_timer -= delta

	velocity.x = dash_direction * dash_speed

	velocity.y = 0

	if dash_timer <= 0:
		is_dashing = false

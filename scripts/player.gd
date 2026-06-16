extends CharacterBody2D

# Movement tuning
@export var acceleration := 1500.0  # Ground acceleration rate
@export var air_acceleration := 800.0  # Air acceleration rate
@export var coyote_time := 0.15  # Grace period for jumping after leaving floor
@export var friction := 1800.0  # Deceleration rate on ground
@export var jump_buffer_time := 0.15  # Grace period for buffered jump input
@export var jump_velocity := -500.0  # Initial upward velocity for jump
@export var jump_cut_multiplier := 0.5  # Velocity multiplier when jump is released early
@export var speed := 300.0  # Maximum horizontal movement speed
@export var fall_death_y := 1000.0  # Y position where player resets
@export var fall_reset_delay := 2.0  # Delay before resetting after falling

# Player state for animation hooks
enum PlayerState { IDLE, RUN, JUMP, FALL }
var current_state := PlayerState.IDLE

# Jump state machine:
#   Ground → coyote_timer set, can_double_jump = false
#   Coyote jump (buffered input + coyote window) → enables can_double_jump = true
#   Mid-air double jump (just_pressed + can_double_jump + !is_on_floor) → consumes it
#   Land → reset cycle
var can_double_jump := false
var coyote_timer := 0.0  # Countdown for coyote window
var fall_timer := 0.0  # Countup for fall reset delay
var jump_buffer_timer := 0.0  # Countdown for jump buffer window
var spawn_position: Vector2  # Respawn position
var was_on_floor := false  # Tracks floor state for landing detection

signal landed  # Emitted when player lands on ground


func _ready() -> void:
	var spawn_point = get_node_or_null("SpawnPoint")
	spawn_position = spawn_point.global_position if spawn_point else position
	add_to_group("player")


func _physics_process(delta: float) -> void:
	_buffer_jump_input()
	_update_timers(delta)
	_update_ground_state(delta)
	_handle_jump()
	_handle_horizontal_movement(delta)
	move_and_slide()
	_update_state()
	_check_fall_reset(delta)


# Stores jump input in a short buffer window so players
# can press jump slightly before landing and still jump.
func _buffer_jump_input() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time


func _update_timers(delta: float) -> void:
	coyote_timer -= delta
	jump_buffer_timer -= delta


# Applies gravity when airborne, resets coyote timer on ground,
# and detects landing transitions.
func _update_ground_state(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
		can_double_jump = false
		if not was_on_floor:
			emit_signal("landed")
			was_on_floor = true
	else:
		velocity += get_gravity() * delta
		was_on_floor = false


# Jump priority:
# 1. Coyote + buffer jump — ground jump with a brief forgiveness window
# 2. Double jump — mid-air second jump
# 3. Variable height — cutting velocity short on jump release
func _handle_jump() -> void:
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


func _handle_horizontal_movement(delta: float) -> void:
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


func _check_fall_reset(delta: float) -> void:
	if position.y > fall_death_y:
		fall_timer += delta
		if fall_timer >= fall_reset_delay:
			_reset_to_spawn()
	elif fall_timer > 0:
		fall_timer = 0.0


func _reset_to_spawn() -> void:
	position = spawn_position
	velocity = Vector2.ZERO
	fall_timer = 0.0
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	can_double_jump = false
	was_on_floor = false

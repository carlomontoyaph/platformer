extends CharacterBody2D

# Movement tuning
const JUMP_VELOCITY := -500.0
const SPEED := 300.0

func _physics_process(delta: float) -> void:
	# Apply gravity when airborne
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump when input is pressed and player is grounded
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle horizontal movement
	var direction = Input.get_axis(
		"move_left",
		"move_right"
	)

	if direction:
		velocity.x = direction * SPEED
	else:
		# Smoothly decelerate to 0 (move_toward gradually changes from current to target by max delta)
		velocity.x = move_toward(
			velocity.x,
			0,
			SPEED
		)

	# Apply velocity and handle collisions
	move_and_slide()

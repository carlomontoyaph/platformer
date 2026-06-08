extends CharacterBody2D

# Movement tuning
@export var acceleration := 1500.0
@export var air_acceleration := 800.0
@export var friction := 1800.0
@export var jump_velocity := -500.0
@export var speed := 300.0

func _physics_process(delta: float) -> void:
	# Apply gravity when airborne
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump when input is pressed and player is grounded
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		
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

extends Label

var player: CharacterBody2D


func _ready() -> void:
	# Defer lookup so Player's _ready() (and its group registration) runs first
	call_deferred("_find_player")


func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")
	if not player:
		text = "ERROR: Player not found"
		printerr("Debug HUD: Could not find Player node")


func _process(_delta: float) -> void:
	if not player:
		return

	var coyote = player.coyote_timer
	var buffer = player.jump_buffer_timer
	var on_floor = player.is_on_floor()
	var vel_y = player.velocity.y
	var vel_x = player.velocity.x

	text = "Coyote: %.3f | Buffer: %.3f | Floor: %s | VelY: %.1f | VelX: %.1f" % [
		max(0.0, coyote), max(0.0, buffer), on_floor, vel_y, vel_x
	]

extends Node2D

# Nomad movement along the selected path
var is_moving = false
var current_path_index = 0
var target_position: Vector2
var movement_speed = 150.0  # pixels per second
var path_nodes: Array = []

# Animation player reference
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Signal to notify when nomad movement is complete
signal nomad_movement_completed

func _ready():
	# Connect to animation finished signal
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

# Start moving along the selected path
func start_path_traversal(selected_path: Array):
	if selected_path.size() < 2:
		print("Nomad: Path too short to traverse")
		nomad_movement_completed.emit()
		return
	
	print("Nomad: Starting path traversal with ", selected_path.size(), " nodes")
	
	# Store the path nodes
	path_nodes = selected_path.duplicate()
	current_path_index = 0
	
	# Start at the first node
	if path_nodes.size() > 0:
		position = path_nodes[0].position
		current_path_index = 1
		print("Nomad: Starting at position ", position)
	
	# Start moving if we have more than one node
	if path_nodes.size() > 1:
		is_moving = true
		_move_to_next_node()
	else:
		print("Nomad: Only one node in path, no movement needed")
		nomad_movement_completed.emit()

# Move to the next node in the path
func _move_to_next_node():
	if current_path_index >= path_nodes.size():
		# Reached the end of the path
		print("Nomad: Reached end of path")
		is_moving = false
		nomad_movement_completed.emit()
		return
	
	# Get the target position
	target_position = path_nodes[current_path_index].position
	print("Nomad: Moving to node ", current_path_index, " at position ", target_position)
	
	# Update sprite direction based on movement
	_update_sprite_direction(target_position)

# Update sprite direction based on movement direction
func _update_sprite_direction(target_pos: Vector2):
	var direction = target_pos - position
	if abs(direction.x) > abs(direction.y):
		# Horizontal movement
		if direction.x > 0:
			# Moving right
			$NomadSprite.flip_h = false
		else:
			# Moving left
			$NomadSprite.flip_h = true
	else:
		# Vertical movement - keep current horizontal flip
		pass

# Called every frame during movement
func _process(delta):
	if not is_moving:
		return
	
	# Move towards target position
	var direction = (target_position - position).normalized()
	var distance_to_target = position.distance_to(target_position)
	
	if distance_to_target > 5.0:  # Close enough threshold
		# Move towards target
		position += direction * movement_speed * delta
		
		# Ensure we don't overshoot the target
		if position.distance_to(target_position) > distance_to_target:
			position = target_position
	else:
		# Reached the target node
		position = target_position
		print("Nomad: Reached node ", current_path_index)
		
		# Move to next node
		current_path_index += 1
		_move_to_next_node()

# Called when the dig animation finishes
func _on_animation_finished(anim_name: String):
	if anim_name == "dig":
		print("Nomad: Dig animation finished, starting path traversal")
		# The path traversal will be started from the level script
		# This is just a placeholder for when the animation completes

# Stop all movement
func stop_movement():
	is_moving = false
	current_path_index = 0
	path_nodes.clear()

# Get current movement status
func is_currently_moving() -> bool:
	return is_moving

# Set movement speed
func set_movement_speed(speed: float):
	movement_speed = speed

extends Node2D

# Nomad movement along the selected path
var path_nodes: Array = []

# Animation player reference
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Signal to notify when nomad movement is complete
signal nomad_movement_completed

func _ready():
	# Connect to animation finished signal
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

# Start moving along the selected path (like river/ditch system)
func start_path_traversal(selected_path: Array):
	if selected_path.size() < 2:
		print("Nomad: Path too short to traverse")
		nomad_movement_completed.emit()
		return
	
	print("Nomad: Starting path traversal with ", selected_path.size(), " nodes")
	
	# Store the path nodes
	path_nodes = selected_path.duplicate()
	
	# Start at the first node
	if path_nodes.size() > 0:
		position = path_nodes[0].position
		print("Nomad: Starting at position ", position)
	
	# Move along the path like the river/ditch system - every 20 pixels
	_move_along_path_step_by_step()
	
	# Signal completion after movement is finished
	nomad_movement_completed.emit()

# Move along the path step by step like the river/ditch system
func _move_along_path_step_by_step():
	if path_nodes.size() < 2:
		return
	
	print("Nomad: Moving along path step by step")
	
	# Get reference to the ditch system for real-time hole placement
	var ditch_system = get_node_or_null("Ditch")
	if not ditch_system:
		print("Nomad: Warning - Ditch system not found, holes won't be placed")
	
	# Move along the path between each pair of pathnodes
	for i in range(path_nodes.size() - 1):
		var start_node = path_nodes[i]
		var end_node = path_nodes[i + 1]
		
		# Calculate the direction vector between nodes
		var direction = (end_node.position - start_node.position).normalized()
		var distance = start_node.position.distance_to(end_node.position)
		
		# Move every 20 pixels along the path (like river/ditch spacing)
		var step_spacing = 20.0
		var current_distance = 0.0
		
		while current_distance < distance:
			# Calculate position for this step
			var step_position = start_node.position + (direction * current_distance)
			
			# Move the nomad to this position
			position = step_position
			
			# Place a hole at this position (real-time synchronization)
			if ditch_system and ditch_system.has_method("place_single_hole_at_position"):
				ditch_system.place_single_hole_at_position(step_position)
			
			# Update sprite direction based on movement
			_update_sprite_direction(step_position)
			
			# Small delay to make the movement visible
			await get_tree().create_timer(0.05).timeout
			
			# Move to next step position
			current_distance += step_spacing
		
		# Ensure we end up exactly at the end node
		position = end_node.position
		_update_sprite_direction(end_node.position)
		
		# Place final hole at the end node
		if ditch_system and ditch_system.has_method("place_single_hole_at_position"):
			ditch_system.place_single_hole_at_position(end_node.position)
	
	print("Nomad: Completed step-by-step movement along path")
	# emit the nomad_movement_completed signal
	nomad_movement_completed.emit()


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



# Called when the dig animation finishes
func _on_animation_finished(anim_name: String):
	if anim_name == "dig":
		print("Nomad: Dig animation finished, starting path traversal")
		# The path traversal will be started from the level script
		# This is just a placeholder for when the animation completes

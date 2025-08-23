extends Node2D

# Function to draw a ditch with multiple hole nodes between pathnodes,
# over time to look like a ditch being dug.
# this function is awaited on in level.gd, so it must be async
func draw_ditch(pathnodes: Array) -> void:
	# Clear existing splash nodes (except the original one)
	for child in $GeneratedSprites.get_children():
		child.queue_free()
	
	# Get the original splash node as a template
	var original_hole = get_node("Hole")
	if not original_hole:
		print("Error: Original Hole node not found!")
		return
	
	# Create hole nodes between each pair of pathnodes
	for i in range(pathnodes.size() - 1):
		var start_node = pathnodes[i]
		var end_node = pathnodes[i + 1]
		
		# Calculate the direction vector between nodes
		var direction = (end_node.position - start_node.position).normalized()
		var distance = start_node.position.distance_to(end_node.position)
		
		# Create splash nodes every 20 pixels along the path
		var current_distance = 0.0
		while current_distance < distance:
			# Calculate position for this hole node
			var hole_position = start_node.position + (direction * current_distance)
			
			# Create a new hole node
			var new_hole = Sprite2D.new()
			new_hole.name = "Hole_" + str(i) + "_" + str(current_distance)
			new_hole.texture = original_hole.texture
			new_hole.scale = original_hole.scale
			new_hole.position = hole_position
			new_hole.z_index = Global.Z_INDEX_DITCH
			new_hole.visible = true  # Make it visible
			#rotate the hole a random amount between 0 and 360 degrees
			new_hole.rotation = randf_range(0, 360)

			# Add the hole node to the scene
			$GeneratedSprites.add_child(new_hole)
			
			# Move 20 pixels closer to the next node
			current_distance += 20.0

			# wait for 0.1 seconds before drawing the next hole
			await get_tree().create_timer(0.1).timeout

	
	print("Ditch drawn with hole nodes between ", pathnodes.size(), " pathnodes")
	Global.level_win_animation_finished.emit()

# Place a single hole at a specific position (for real-time synchronization with nomad)
func place_single_hole_at_position(pos: Vector2) -> void:
	# Get the original hole node as a template
	var original_hole = get_node("Hole")
	if not original_hole:
		print("Error: Original Hole node not found!")
		return
	
	# Create a new hole node
	var new_hole = Sprite2D.new()
	new_hole.name = "Hole_Sync_" + str(randi())  # Unique name
	new_hole.texture = original_hole.texture
	new_hole.scale = original_hole.scale
	new_hole.position = pos
	new_hole.z_index = Global.Z_INDEX_DITCH
	new_hole.visible = true
	
	# Rotate the hole a random amount between 0 and 360 degrees
	new_hole.rotation = randf_range(0, 360)
	
	# Add the hole node to the scene
	$GeneratedSprites.add_child(new_hole)
	
	print("Ditch: Placed hole at position ", pos)

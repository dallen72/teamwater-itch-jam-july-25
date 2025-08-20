extends Node2D

# Function to draw a river with multiple splash nodes between pathnodes,
# over time to look like a river flowing.
func draw_river(pathnodes: Array) -> void:
	# Clear existing splash nodes (except the original one)
	for child in $GeneratedSprites.get_children():
		child.queue_free()
	
	# Get the original splash node as a template
	var original_splash = get_node("Splash")
	if not original_splash:
		print("Error: Original Splash node not found!")
		return
	
	# Create splash nodes between each pair of pathnodes
	for i in range(pathnodes.size() - 1):
		var start_node = pathnodes[i]
		var end_node = pathnodes[i + 1]
		
		# Calculate the direction vector between nodes
		var direction = (end_node.position - start_node.position).normalized()
		var distance = start_node.position.distance_to(end_node.position)
		
		# Create splash nodes every 20 pixels along the path
		var current_distance = 0.0
		while current_distance < distance:
			# Calculate position for this splash node
			var splash_position = start_node.position + (direction * current_distance)
			
			# Create a new splash node
			var new_splash = Sprite2D.new()
			new_splash.name = "Splash_" + str(i) + "_" + str(current_distance)
			new_splash.texture = original_splash.texture
			new_splash.scale = original_splash.scale
			new_splash.position = splash_position
			new_splash.visible = true  # Make it visible
			#rotate the splash a random amount between 0 and 360 degrees
			new_splash.rotation = randf_range(0, 360)

			# Add the splash node to the scene
			$GeneratedSprites.add_child(new_splash)
			
			# Move 20 pixels closer to the next node
			current_distance += 20.0

			# wait for 0.1 seconds before drawing the next splash
			await get_tree().create_timer(0.1).timeout

		# Also place a splash node at the end node position
		var final_splash = Sprite2D.new()
		final_splash.name = "Splash_" + str(i) + "_final"
		final_splash.texture = original_splash.texture
		final_splash.scale = original_splash.scale
		final_splash.position = end_node.position
		final_splash.visible = true
		
		$GeneratedSprites.add_child(final_splash)
	
	print("River drawn with splash nodes between ", pathnodes.size(), " pathnodes")

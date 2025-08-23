class_name CheckpointManager
extends Node2D

# Signal emitted when a checkpoint is reached
signal checkpoint_reached(checkpoint_name)
# Signal emitted when a checkpoint is reset (unselected)
signal checkpoint_reset(checkpoint_name)

# Track which checkpoints have been reached
var reached_checkpoints = {}
var checkpoints = []

func _ready():
	init_checkpoints()

func init_checkpoints():
	# First try to find checkpoints in the CheckPoint group
	checkpoints = get_tree().get_nodes_in_group("CheckPoint")
	
	# If no checkpoints found in group, try to find them in PathManager
	if checkpoints.size() == 0:
		checkpoints = []
		var path_manager = get_parent().get_node_or_null("PathManager")
		if path_manager:
			for child in path_manager.get_children():
				if "CheckPoint" in child.name:
					checkpoints.append(child)
	
	if checkpoints.size() > 0:
		for i in range(checkpoints.size()):
			var checkpoint = checkpoints[i]
			# Make sure checkpoint is visible
			checkpoint.show()
		
		checkpoint_reached.connect(_on_checkpoint_reached)
		checkpoint_reset.connect(_on_checkpoint_reset)
		
		# Initialize checkpoint tracking
		reached_checkpoints = {}
		for i in range(checkpoints.size()):
			reached_checkpoints["checkpoint_" + str(i)] = false
	else:
		print("ERROR: No checkpoints found")


# Called when a checkpoint is reached
func _on_checkpoint_reached(_checkpoint_name):
	# Mark this checkpoint as reached
	if reached_checkpoints.has(_checkpoint_name):
		reached_checkpoints[_checkpoint_name] = true
		
		# Check if all checkpoints have been reached
		var all_reached = true
		for checkpoint in reached_checkpoints.values():
			if not checkpoint:
				all_reached = false
				break
		
		# Show win popup only when all checkpoints are reached
		if all_reached:
			# emit level_completed signal
			Global.level_completed.emit()

# Called when a checkpoint is reset (unselected)
func _on_checkpoint_reset(_checkpoint_name):
	# Mark this checkpoint as unreached
	if reached_checkpoints.has(_checkpoint_name):
		reached_checkpoints[_checkpoint_name] = false

# Check if a node is a checkpoint
func is_checkpoint(node: PathNode) -> bool:
	# Simple check: if the node has the checkpoint property set to true
	return node.checkpoint == true

# Get checkpoint name for a node
func get_checkpoint_name(node: PathNode) -> String:
	if node.checkpoint_name != "":
		return node.checkpoint_name
	else:
		# Fallback: find the checkpoint in our list and return its index
		for i in range(checkpoints.size()):
			if checkpoints[i] == node:
				return "checkpoint_" + str(i)
	return ""

# Get all checkpoints
func get_checkpoints() -> Array:
	return checkpoints

# Get checkpoint count
func get_checkpoint_count() -> int:
	return checkpoints.size()

# Get reached checkpoint count
func get_reached_checkpoint_count() -> int:
	var count = 0
	for reached in reached_checkpoints.values():
		if reached:
			count += 1
	return count 

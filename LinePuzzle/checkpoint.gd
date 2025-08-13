
extends Node2D

const PathNode = preload("res://LinePuzzle/pathnode.gd")

func _ready():
	add_to_group("CheckPoint")
	print("Checkpoint added to group CheckPoint")
	
	
# Takes a grid node (PathNode instance) and sets it up as a checkpoint
func show_closest_node_as_checkpoint(node: PathNode, checkpoint_id: int) -> void:
	node.checkpoint = true
	node.checkpoint_id = checkpoint_id
	node.checkpoint_name = "checkpoint_" + str(checkpoint_id)
	# Make the checkpoint visible with green color
	node.make_visible()
	if node.has_node("VisibleShape"):
		node.get_node("VisibleShape").color = Color.GREEN 

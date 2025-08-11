
extends Node2D

func _ready():
	add_to_group("EndPoint")
	
	
func show_closest_node_as_end_point(node):
	node.checkpoint = true
	node.checkpoint_name = "end_point"
	node.get_node("VisibleShape").color = Color.GREEN
	node.get_node("VisibleShape").show()

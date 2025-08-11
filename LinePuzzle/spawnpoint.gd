
extends Node2D

func _ready():
	add_to_group("SpawnPoint")
	
	
func show_closest_node_as_spawn_point(node):
	node.get_node("VisibleShape").color = Color.BLUE
	node.get_node("VisibleShape").show()

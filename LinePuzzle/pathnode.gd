class_name PathNode
extends Node2D

var is_selected = false
var checkpoint = false
var checkpoint_name = ""
var checkpoint_id = -1

func _ready():
	add_to_group("GridNode")

func toggle_selection():
	is_selected = !is_selected
	
	if is_selected:
		$VisibleShape.color = Color.WHITE
	else:
		$VisibleShape.color = Color(0.2, 0.8, 0.2, 1)  # Green color


func make_visible():
	$VisibleShape.show()
	
	
func make_invisible():
	$VisibleShape.hide()

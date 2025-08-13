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
		# If this is a checkpoint, restore checkpoint appearance
		if checkpoint:
			$VisibleShape.color = Color.GREEN
			$VisibleShape.show()  # Ensure checkpoint is visible
		else:
			$VisibleShape.color = Color(0.2, 0.8, 0.2, 1)  # Default green color


func make_visible():
	$VisibleShape.show()
	
	
func make_invisible():
	$VisibleShape.hide()

func restore_checkpoint_appearance():
	# Restore checkpoint appearance if this node is a checkpoint
	if checkpoint:
		$VisibleShape.color = Color.GREEN
		$VisibleShape.show()
		print("Restored checkpoint appearance for: ", checkpoint_name)


extends Node2D


# Export the level number so it can be set in the editor
@export var level_number: int = 1

# Export the starting energy for this level
@export var starting_energy: int = 400


func _ready():
	# Enable input processing for this node
	set_process_input(true)
	print("Level _ready() called - input processing enabled for level ", level_number)
	
	# Set global level number for other systems to use (keeping for backward compatibility)
	Global.level_num = level_number
	Global.level_completed.connect(_on_level_completed)
	
	# Set starting energy for current level
	PlayerEnergy.player_energy = starting_energy
	Global.energy_changed.emit(starting_energy)
	
	# Initialize UI
	init_ui()
	$Nomad/River.position = $PathManager/SpawnPoint.position
	Global.input_enabled = true

	# for every child node that is in the group Scenery, set the z_index to 5
	for child in get_tree().get_nodes_in_group("Scenery"):
		child.z_index = Global.Z_INDEX_SCENERY


func init_ui():
	# Show tutorial dialogue for level 1
	if level_number == 1:
		await get_tree().process_frame
		var ui = get_node_or_null("UI")
		if ui:
			ui.show_dialogue()
			
			
func _input(event):
	print("Level _input called with event: ", event)
	Global.handle_input(event)


# play the animations, and when they are done, show the win popup
func _on_level_completed():
	# disable input
	Global.input_enabled = false

	# hide the lines and nodes
	$PathManager.hide()
	# for every child node of the path manager, if it has a "hide" method, call it
	for child in $PathManager.get_children():
		if child.has_method("hide"):
			child.hide()

	# player digging animation
	$Nomad.z_index = Global.Z_INDEX_SCENERY_BEHIND
	$Nomad/AnimationPlayer.play("dig")

	await get_tree().create_timer(0.1).timeout		
	# Make ditch system visible for real-time hole placement
	$Nomad/Ditch.visible = true		

	# Start nomad moving along the selected path
	var nomad = $Nomad
	if nomad and nomad.has_method("start_path_traversal"):
		nomad.start_path_traversal($PathManager.selected_path)
		# Wait for nomad movement to complete
		await nomad.nomad_movement_completed

	$Nomad/AnimationPlayer.stop()
	$Nomad/NomadSprite.hide()
	$Nomad/DirtSprite.hide()

	# play river animation
	$Nomad/River.visible = true
	$Nomad/River.draw_river($PathManager.selected_path)
	await Global.level_win_animation_finished
	$Nomad/Ditch/Hole.hide()
	$Nomad/River/Splash.hide()

	
	# show win popup
	var win_popup = get_node_or_null("WinPopupUI")
	if win_popup:
		Global.dialogue_finished.emit()
		win_popup.show()

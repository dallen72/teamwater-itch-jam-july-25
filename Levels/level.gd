
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
	$River.position = $PathManager/SpawnPoint.position
	Global.input_enabled = true


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
	# TODO: play the animation

	# play river animation
	$River.visible = true
	$River.draw_river($PathManager.selected_path)
	await Global.level_win_animation_finished
	# show win popup
	var win_popup = get_node_or_null("WinPopupUI")
	if win_popup:
		win_popup.show()

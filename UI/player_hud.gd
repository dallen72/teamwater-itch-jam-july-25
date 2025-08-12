extends Control

func init_hud():
	if (Global.level_num == 1): 
		# show tutorial instructions
		show_dialogue()
	Global.dialogue_finished.connect(hide_dialogue)
	
	update_energy_display(PlayerEnergy.player_energy)
	Global.energy_changed.connect(update_energy_display, PlayerEnergy.player_energy)


func show_dialogue():
	$PortraitBox.show()


func hide_dialogue():
	$PortraitBox.hide()
	
	
func update_energy_display(_energy_level):
	$EnergyBox/RichTextLabel.text = str(_energy_level)	

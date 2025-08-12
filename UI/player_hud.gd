extends Control


func _ready():
	if (Global.level_num == 1): 
		# show tutorial instructions
		show_dialogue()
	
	Global.dialogue_finished.connect(hide_dialogue)


func show_dialogue():
	$PortraitBox.show()


func hide_dialogue():
	$PortraitBox.hide()
	print("debug")

extends 'res://Levels/level.gd'

# need to call super
func _ready():
	PlayerEnergy.player_energy = 910
	Global.energy_changed.emit(910)
	super()
	$UI.init_hud()


#TODO: check to make sure that the correct script is connected to each level

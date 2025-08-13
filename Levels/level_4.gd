extends 'res://Levels/level.gd'

# need to call super
func _ready():
	PlayerEnergy.player_energy = 900
	Global.energy_changed.emit(900)
	super()
	$UI.init_hud()


#TODO: check to make sure that the correct script is connected to each level

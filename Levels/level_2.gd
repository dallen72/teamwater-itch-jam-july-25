extends 'res://Levels/level.gd'

# need to call super
func _ready():
	PlayerEnergy.player_energy = 700
	Global.energy_changed.emit(700)
	super()
	$UI.init_hud()

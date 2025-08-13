extends 'res://Levels/level.gd'

# need to call super
func _ready():
	PlayerEnergy.player_energy = 600
	Global.energy_changed.emit(600)
	super()
	$UI.init_hud()

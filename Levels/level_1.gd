extends 'res://Levels/level.gd'

const STARTING_ENERGY = 400

# need to call super
func _ready():
	PlayerEnergy.player_energy = STARTING_ENERGY
	Global.energy_changed.emit(STARTING_ENERGY)
	super()
	$UI.init_hud()

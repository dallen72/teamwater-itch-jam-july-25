extends Node

# Global player energy singleton
# This script should be added as an AutoLoad in Project Settings

const STARTING_ENERGY = 400
var player_energy: int = STARTING_ENERGY

# Signal emitted when energy changes
signal energy_depleted

# Function to decrease energy by a given amount
func decrease_energy(amount: int) -> bool:
	if player_energy - amount < 0:
		return false  # Cannot decrease below zero
	
	player_energy -= amount
	Global.energy_changed.emit(player_energy)
	
	if player_energy <= 0:
		energy_depleted.emit()
	
	return true

# Function to increase energy by a given amount
func increase_energy(amount: int):
	player_energy += amount
	Global.energy_changed.emit(player_energy)

# Function to check if energy can be decreased by a given amount
func can_decrease_energy(amount: int) -> bool:
	return player_energy - amount >= 0

# Function to get current energy
func get_energy() -> int:
	return player_energy

# Function to reset energy (useful for restarting levels)
func reset_energy():
	player_energy = STARTING_ENERGY
	Global.energy_changed.emit() 

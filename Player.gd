# Player.gd
extends Node

var puzzle_node  # Reference to the main puzzle node

func _init(puzzle):
	puzzle_node = puzzle

func on_tile_clicked(tile_pos: Vector2):
	puzzle_node.try_move_tile(tile_pos)

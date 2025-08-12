
extends Node2D


func _ready():
	Global.level_num += 1


func _input(event):
	Global.handle_input(event)

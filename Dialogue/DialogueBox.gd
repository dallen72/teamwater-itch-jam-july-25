# DialogueData.gd
class_name DialogueData
extends Control


@export var character_name: String
@export var character_portrait: Texture2D
@export var dialogue_lines: Array[String] = []

func _init(_name: String = "", portrait: Texture2D = null, lines: Array[String] = []):
	character_name = _name
	character_portrait = portrait
	dialogue_lines = lines

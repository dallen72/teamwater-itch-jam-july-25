class_name DialogueEntry
extends Resource

@export var character_name: String
@export var portrait_texture: Texture2D
@export var dialogue_text: String

func _init(p_character_name: String = "", p_portrait_texture: Texture2D = null, p_dialogue_text: String = ""):
	character_name = p_character_name
	portrait_texture = p_portrait_texture
	dialogue_text = p_dialogue_text 
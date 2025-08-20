class_name DialogueManager
extends Control

# Dialogue state
var current_dialogue: Array[DialogueEntry] = []
var current_index: int = 0
var is_dialogue_active: bool = false

# UI references
@onready var dialogue_ui: DialogueUI = $DialogueUI

func _ready():
	# Hide dialogue initially
	visible = false
	# Register this UI area with the global click handler (after first frame)
	await get_tree().process_frame
	

# Load dialogue from a JSON file
func load_dialogue_from_json(json_file_path: String):
	var dialogue_entries = parse_dialogue_json(json_file_path)
	if dialogue_entries.size() > 0:
		load_dialogue(dialogue_entries)
	else:
		print("ERROR: Failed to load dialogue from ", json_file_path)

# Parse JSON file and convert to DialogueEntry objects
func parse_dialogue_json(json_file_path: String) -> Array[DialogueEntry]:
	var dialogue_entries: Array[DialogueEntry] = []
	
	# Load and parse JSON file
	var json_file = FileAccess.open(json_file_path, FileAccess.READ)
	if not json_file:
		print("ERROR: Could not open dialogue file: ", json_file_path)
		return dialogue_entries
	
	var json_string = json_file.get_as_text()
	json_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("ERROR: Failed to parse JSON from ", json_file_path)
		return dialogue_entries
	
	var json_data = json.data
	if not json_data.has("dialogue_entries"):
		print("ERROR: JSON file missing 'dialogue_entries' key")
		return dialogue_entries
	
	# Convert JSON data to DialogueEntry objects
	for entry_data in json_data.dialogue_entries:
		var character_name = entry_data.get("character_name", "")
		var portrait_path = entry_data.get("portrait_path", "")
		var dialogue_text = entry_data.get("dialogue_text", "")
		
		# Load portrait texture
		var portrait_texture: Texture2D = null
		if portrait_path != "":
			portrait_texture = load(portrait_path)
			if not portrait_texture:
				print("WARNING: Could not load portrait from ", portrait_path)
		
		# Create dialogue entry
		var entry = DialogueEntry.new(character_name, portrait_texture, dialogue_text)
		dialogue_entries.append(entry)
	
	print("Loaded ", dialogue_entries.size(), " dialogue entries from ", json_file_path)
	return dialogue_entries

# Load dialogue from an array of DialogueEntry objects
func load_dialogue(dialogue_entries: Array[DialogueEntry]):
	current_dialogue = dialogue_entries
	current_index = 0
	is_dialogue_active = true
	visible = true
	
	# Display first line
	display_current_line()

# Display the current dialogue line
func display_current_line():
	if current_index < current_dialogue.size() and dialogue_ui:
		var entry = current_dialogue[current_index]
		dialogue_ui.display_dialogue_entry(entry)

# Move to next line
func next_line():
	current_index += 1
	
	if current_index < current_dialogue.size():
		display_current_line()
	else:
		end_dialogue()

# End the current dialogue
func end_dialogue():
	is_dialogue_active = false
	visible = false
	Global.dialogue_finished.emit()
	Global.unregister_ui_area(self)

# Check if dialogue is currently active
func is_active() -> bool:
	return is_dialogue_active

# Get current dialogue entry
func get_current_entry() -> DialogueEntry:
	if current_index < current_dialogue.size():
		return current_dialogue[current_index]
	return null 


extends Node2D

# Signal for spawn point clicks
signal spawn_point_clicked(spawn_point)

# Click area for spawn point interaction
var click_area: Area2D
var collision_shape: CollisionShape2D

func _ready():
	add_to_group("SpawnPoint")
	setup_click_area()

func setup_click_area():
	# Create click area for interaction
	click_area = Area2D.new()
	add_child(click_area)
	
	# Add collision shape
	collision_shape = CollisionShape2D.new()
	click_area.add_child(collision_shape)
	
	# Set up collision shape (adjust size as needed)
	var shape = CircleShape2D.new()
	shape.radius = 20.0  # Adjust this value for click area size
	collision_shape.shape = shape
	
	
func show_as_spawn_point(node):
	node.get_node("VisibleShape").color = Color.BLUE
	node.get_node("VisibleShape").show()

extends Camera2D

@export var follow_character: bool = true
@export var offset_distance: Vector2 = Vector2(0, -50)
@export var smooth_speed: float = 5.0

var target: Node2D

func _ready():
	target = get_node("../Path2D/PathFollow2D")  # Adjust path as needed

func _process(delta):
	if follow_character and target:
		var target_pos = target.global_position + offset_distance
		global_position = global_position.lerp(target_pos, smooth_speed * delta)

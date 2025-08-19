extends PathFollow2D

@export var speed: float = 100.0
@export var loop_path: bool = false

func _ready():
	# Make character a child of PathFollow2D
	pass

func _process(delta):
	progress += speed * delta
	
	# Loop or stop at end
	if loop_path and progress_ratio >= 1.0:
		progress_ratio = 0.0
	elif progress_ratio >= 1.0:
		progress_ratio = 1.0

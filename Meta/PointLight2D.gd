extends PointLight2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	energy = randf_range(0.9, 1.0)

extends GPUParticles2D

func _ready():
	$Timer.wait_time = lifetime
	$Timer.start()

func _on_timer_timeout():
	queue_free()

extends StaticBody2D

signal barracade_done

var im_a_slime = false
var in_main_world = true
var im_a_barracade = true

var active = false
var health = 6

var particles_object = preload("res://Objects/particles.tscn")

func _ready():
	create_particle_explosion(Color.WHITE_SMOKE)

func barracade_tick():
	if active:
		health -= 1
		GlobalStats.play_sound("Hurt")
		if health <= 0:
			create_particle_explosion(Color.SANDY_BROWN)
			GlobalStats.play_sound("Death")
			emit_signal("barracade_done")
			get_parent().shake_camera(10)
			queue_free()
		else:
			get_parent().shake_camera(3, 0.4)

func create_particle_explosion(color):
	var particles = particles_object.instantiate()
	particles.emitting = true
	particles.position = position
	particles.modulate = color
	get_parent().add_child(particles)
	return particles

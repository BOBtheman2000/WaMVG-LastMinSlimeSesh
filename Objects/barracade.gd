extends StaticBody2D

signal barracade_done

var im_a_slime = false
var in_main_world = true
var im_a_barracade = true

var active = false
var health = 6

var shake_time = 0
var default_x_pos = 0

var particles_object = preload("res://Objects/particles.tscn")

func _ready():
	create_particle_explosion(Color.WHITE_SMOKE)
	default_x_pos = position.x
	$Sprite.frame = 0

func _physics_process(_delta):
	if shake_time > 0:
		position.x = default_x_pos + sin(Time.get_ticks_msec()) * shake_time * 0.4
		shake_time -= 1

func barracade_tick():
	if active:
		health -= 1
		$Sprite.frame = (6 - (health - 1))/2
		GlobalStats.play_sound("Hurt")
		shake_time += 10
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

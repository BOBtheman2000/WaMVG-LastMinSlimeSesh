extends TextureButton

@export var socials_link: String

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("pressed", on_click)
	connect("mouse_entered", on_hover)
	connect("mouse_exited", on_unhover)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func on_click():
	OS.shell_open(socials_link)
	on_unhover()

func on_hover():
	pivot_offset = size / 2.0
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(self, "rotation_degrees", randf_range(-0.4, 0.4), 0.3)

func on_unhover():
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_property(self, "rotation_degrees", 0, 0.3)

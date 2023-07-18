extends TextureButton

@export var socials_link: String

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("pressed", on_click)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func on_click():
	OS.shell_open(socials_link)

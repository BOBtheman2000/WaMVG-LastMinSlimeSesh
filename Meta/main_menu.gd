extends Control

var default_title_y = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	default_title_y = $Title.position.y
	GlobalStats.play_music("Menu")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$BG.region_rect.position.x += 0.4
	$BG/LeftLight.energy = randf_range(1.2, 1.1)
	$BG/LeftLight2.energy = randf_range(1.2, 1.1)
	
	$Title.position.y = default_title_y + sin(Time.get_ticks_msec() / 200) * 10

func _on_credits_pressed():
	$Title.visible = false
	$Interactibles/GameButtons.visible = false
	$Interactibles/Credits.visible = true
	$Back.visible = true
	$Tutorial.visible = false

func _on_back_pressed():
	$Title.visible = true
	$Interactibles/GameButtons.visible = true
	$Interactibles/Credits.visible = false
	$Back.visible = false
	$Tutorial.visible = false

func _on_play_pressed():
	$Title.visible = false
	$Interactibles/GameButtons.visible = false
	$Interactibles/Credits.visible = false
	$Back.visible = false
	$Tutorial.visible = true


func _on_play_fr_pressed():
	GlobalStats.set_default_stats()
	get_tree().change_scene_to_file("res://Meta/gameactual.tscn")

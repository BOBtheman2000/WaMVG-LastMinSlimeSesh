extends Node

var gold = 0
var fading = false

# Called when the node enters the scene tree for the first time.
func _ready():
	set_default_stats()

# Call when new run starts ig
func set_default_stats():
	gold = 0

func add_gold(amount):
	gold += amount
	get_tree().call_group("Labels", "update_label")
	get_tree().call_group("GoldItems", "gold_update")

func play_sound(path):
	var sound_node = get_node("Sounds/"+path)
	sound_node.pitch_scale = randf_range(0.9, 1.1)
	sound_node.play()

func play_music(path):
	for song in $Music.get_children():
		song.stop()
	var song_node = get_node("Music/"+path)
	song_node.play()

func fade_out_music():
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property($Music/Game, "volume_db", -80, 2)
	tween.tween_callback($Music/Game.stop)
	tween.tween_property($Music/Game, "volume_db", 0, 0)

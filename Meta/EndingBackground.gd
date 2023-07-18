extends ColorRect

var active = false

var timer_going = true
var game_timer = 0

func _ready():
	$Button.visible = false
	game_timer = 0

func _process(delta):
	if timer_going:
		game_timer += delta
		var printed_time = floor(game_timer)
		$Time.text = "Your time: " + str(floor(printed_time / 60)) + ":" + ('%02d' % fmod(printed_time, 60))

func fade_onscreen(win: bool):
	if !active:
		timer_going = false
		if win:
			$Time.visible = true
			GlobalStats.play_music("Victory")
			$EndingOutcome.text = "You Win!"
		else:
			$Time.visible = false
			GlobalStats.play_music("Defeat")
			$EndingOutcome.text = "You Lose"
		active = true
		$Button.visible = true
		var tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_QUINT)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate:a", 0.8, 1.2)

func _on_button_pressed():
	get_tree().change_scene_to_file("res://Meta/main_menu.tscn")

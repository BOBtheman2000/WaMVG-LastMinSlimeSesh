extends Label

# Called every frame. 'delta' is the elapsed time since the previous frame.
func update_label():
	text = str(GlobalStats.gold) + "g"

extends Control

func _ready():
	position.y = 800

func update_label(amount):
	$HPBar.value = amount

func set_default(hpMax):
	$HPBar.max_value = hpMax
	$HPBar.value = hpMax

func fade_onscreen():
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", 182, 1.2)

extends Label

const TWEEN_TIME = 1.0
const TEXT_DISTANCE = 50
const TEXT_VARIATION = 20

# Called when the node enters the scene tree for the first time.
func _ready():
	modulate.a = 1
	
	var tween_a = get_tree().create_tween()
	var tween_b = get_tree().create_tween()
	
	tween_a.set_trans(Tween.TRANS_CIRC)
	tween_a.set_ease(Tween.EASE_OUT)
	
	tween_b.set_trans(Tween.TRANS_CIRC)
	tween_b.set_ease(Tween.EASE_IN)
	
	var target_position = Vector2(position.x + randf_range(-TEXT_VARIATION, TEXT_VARIATION), position.y - TEXT_DISTANCE)
	
	tween_a.tween_property(self, "position", target_position, TWEEN_TIME)
	tween_b.tween_property(self, "modulate:a", 0, TWEEN_TIME)
	
	tween_b.tween_callback(queue_free)

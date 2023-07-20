extends Area2D

var item_types = [
	"spears",
	"staves",
	"swords"
]

@export var item_type = 0
@export var item_index = 0
var item_price = 10
var item_soldout = false

var item_shake_time = 0
var item_position_default = Vector2(0, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	update_item_display()
	item_position_default = position
	$ItemPrice.modulate = Color.BLACK

func _physics_process(delta):
	if item_shake_time > 0:
		position.y = item_position_default.y + sin(Time.get_ticks_msec()) * item_shake_time * 0.4
		item_shake_time -= 1

func land_on_item():
	if GlobalStats.gold >= item_price and !item_soldout:
		GlobalStats.add_gold(-item_price)
		
		var purchased_item = Vector2i(item_type, item_index)
		
		item_index += 1
		if item_index >= 10:
			item_soldout = true
		item_price += 5
		update_item_display()
		GlobalStats.play_sound("Money")
		return purchased_item
	
	GlobalStats.play_sound("No")
	shake_item()
	return false

func update_item_display():
	if item_soldout:
		$ItemSprite.animation = "other"
		$ItemSprite.frame = 1
		$ItemPrice.visible = false
		return
	$ItemSprite.animation = item_types[item_type]
	$ItemSprite.frame = item_index
	$ItemPrice.text = str(item_price) + "g"

func gold_update():
	if item_price <= GlobalStats.gold:
		if $ItemPrice.modulate == Color.BLACK:
			$ItemPrice.modulate = Color.GOLDENROD
			var tween = get_tree().create_tween()
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.set_ease(Tween.EASE_IN)
			tween.tween_property($ItemPrice, "modulate", Color.WHITE, 0.4)
	else:
		$ItemPrice.modulate = Color.BLACK

func shake_item():
	item_shake_time += 5

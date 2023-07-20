extends Node2D

var world_thresh
var gold_thresh_x
var health_thresh_x
var barracade_thresh_x

var health_price = 5
var barracade_price = 5

func _ready():
	
	world_thresh = %RealWorldThresh.position
	gold_thresh_x = $MiningBG.get_rect().size.x * $MiningBG.scale.x
	health_thresh_x = $HealthPickupBG.position.x
	barracade_thresh_x = $BarracadeBG.position.x
	
	$HealthPickupBG/Price.modulate = Color.BLACK
	$BarracadeBG/Price.modulate = Color.BLACK
	
	health_price = 5
	barracade_price = 5
	
	update_prices()

func update_prices():
	$HealthPickupBG/Price.text = str(health_price) + "g"
	$BarracadeBG/Price.text = str(barracade_price) + "g"

func increment_health_price():
	health_price += 5
	update_prices()

func increment_barracade_price():
	barracade_price += 5
	update_prices()

func gold_update():
	if health_price <= GlobalStats.gold:
		if $HealthPickupBG/Price.modulate == Color.BLACK:
			$HealthPickupBG/Price.modulate = Color.GOLDENROD
			var tween = get_tree().create_tween()
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.set_ease(Tween.EASE_IN)
			tween.tween_property($HealthPickupBG/Price, "modulate", Color.WHITE, 0.4)
	else:
		$HealthPickupBG/Price.modulate = Color.BLACK
	
	if barracade_price <= GlobalStats.gold:
		if $BarracadeBG/Price.modulate == Color.BLACK:
			$BarracadeBG/Price.modulate = Color.GOLDENROD
			var tween = get_tree().create_tween()
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.set_ease(Tween.EASE_IN)
			tween.tween_property($BarracadeBG/Price, "modulate", Color.WHITE, 0.4)
	else:
		$BarracadeBG/Price.modulate = Color.BLACK

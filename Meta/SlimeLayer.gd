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

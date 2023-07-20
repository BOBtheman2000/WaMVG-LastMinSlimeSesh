extends StaticBody2D

### SCRIPT FOR BOTH PLAYERS AND SLIMES
# This code is beyond a mess, I definitely wouldn't write anything like this outside of a jam context
# However, we only have 48 hours to make a wholeass video game
# Data will vary between being used for slimes and player units, or both
# This concept doesn't seem feasibly expandable into anything big so it's fine

const MOVEMENT_SPEED = 180
const ENDING_SPEED = 600

const DRAGON_DAMAGE = 2

const WEAPON_MULTIPLIERS = [
	1.2,
	1.4,
	1.6,
	1.8,
	2.0,
	2.2,
	2.4,
	2.6,
	2.8,
	3.0
]

enum SLIME_ACTIVITIES {
	NONE,
	MINING,
	EXERCISE
}

# Don't ask
var im_a_barracade = false

var stopped_for_barracade = false

@export_category("Slime Stuffs")
@export var im_a_slime = false
@export var slime_color = Color(0, 1, 0)
var hotbar_pos = Vector2(0, 0)
var slime_activity = SLIME_ACTIVITIES.NONE

var slime_cooldown = 5
var slime_cooldown_max = 5

var slime_progress_mining = 0
var slime_progress_mining_max = 0.5

var slime_progress_exercise = 0
var slime_progress_exercise_max = 0.5

@export_category("Player Stuffs")
@export var player_type = 0
var dead = false

var ending = false
var end_phase = 0

@export_category("Stats")
@export var health = 20
var max_hp
@export var level = 1

var has_health_pickup = false
var has_weapon = false
var weapon = Vector2i(0, 0)

@export_category("Other Shit")
var target_enemy: Node

# A lot of these are slime params
var fighting = false
var hovered = false
var held = false
var releasing = false
var schedule_damage_pulse = false
@export var in_main_world = true

var weapon_types = [
	"spears",
	"staves",
	"swords"
]

var taken_damage = 0

@export var damage_text_object: PackedScene
var particles_object = preload("res://Objects/particles.tscn")
var coin_particles = preload("res://Assets/CoinParticle.png")

var open_mouse = preload("res://Assets/Hand_Open.png")
var grab_mouse = preload("res://Assets/Hand_ClosedNew.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	$Sprite.speed_scale = randf_range(0.9, 1.1)
	max_hp = health
	if in_main_world:
		add_to_world()
	if im_a_slime:
		$Sprite.modulate = slime_color
		hotbar_pos = position
	
	if !im_a_slime:
		$Sprite.animation = ["ranger", "wizard", "knight"][player_type]

func add_to_world():
	if im_a_slime:
		position.y = max(min(position.y, 450), 180)
		position.x = max(position.x, (get_parent().get_node("WorldCamera").position + get_parent().get_node("WorldCamera/CombatZone").position).x - 400)
	toggle_hp_bar_display(true, "health")
	get_parent().connect("we_fight", _on_game_world_we_fight)
	get_parent().connect("combat_tick", _on_game_world_combat_tick)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var movement = Vector2(0, 0)
	if !fighting and !stopped_for_barracade:
		if im_a_slime and !held:
			movement.x -= MOVEMENT_SPEED
		else:
			if ending:
				movement.x += ENDING_SPEED
			else:
				movement.x += MOVEMENT_SPEED
	if in_main_world and !(ending and end_phase == 0):
		position += movement * delta
	
	if slime_cooldown < slime_cooldown_max:
		slime_cooldown += delta
		$HPBar.value = slime_cooldown
		if slime_cooldown >= slime_cooldown_max:
			toggle_hp_bar_display(false)
			modulate = Color.WHITE
			$Sprite.speed_scale = randf_range(0.9, 1.1)
	
	if hovered and Input.is_action_just_pressed("grab_slime"):
		get_tree().set_group("Slimes", "hovered", false)
		hovered = true
		held = true
		slime_activity = SLIME_ACTIVITIES.NONE
		toggle_hp_bar_display(false)
		$Sprite.play("grab")
		GlobalStats.play_sound("Grab")
		Input.set_custom_mouse_cursor(grab_mouse)
	
	if held:
		held = Input.is_action_pressed("grab_slime")
		position = get_parent().get_local_mouse_position()
		
		if !Input.is_action_pressed("grab_slime"):
			release_slime()
	else:
		if releasing:
			unhover_slime()
	
	if schedule_damage_pulse:
		schedule_damage_pulse = false
		modulate = Color("FF0000")
		var tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_QUINT)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate", Color("FFFFFF"), 0.3)
	
	if taken_damage > 0:
		create_damage_text(taken_damage)
		taken_damage = 0
	
	### ACTIVITIES
	if !ending:
		match slime_activity:
			SLIME_ACTIVITIES.MINING:
				slime_progress_mining += delta
				$HPBar.value = slime_progress_mining
				if slime_progress_mining > slime_progress_mining_max:
					slime_progress_mining = 0
					GlobalStats.add_gold(level)
					var particles = create_particle_explosion(Color.GOLDENROD)
					particles.texture = coin_particles
					GlobalStats.play_sound("SmallMoney")
			SLIME_ACTIVITIES.EXERCISE:
				slime_progress_exercise += delta
				$HPBar.value = slime_progress_exercise
				if slime_progress_exercise > slime_progress_exercise_max:
					slime_progress_exercise = 0
					level_up(1)

func add_to_combat():
	if in_main_world:
		fighting = true
		reset_target_enemy()

func reset_target_enemy():
	if im_a_slime:
		target_enemy = get_closest_enemy(get_parent().tracked_players)
	else:
		target_enemy = get_closest_enemy(get_parent().tracked_slimes)

func get_closest_enemy(array):
	var closest = array[0]
	var closest_dist = Vector2.INF
	for object in array:
		if object.fighting and object.in_main_world and !dead:
			if object.position.distance_to(position) < closest_dist.distance_to(position):
				closest = object
				closest_dist = object.position
	return closest

func get_closest_from(array):
	var closest = array[0]
	var closest_dist = INF
	var comp_position = closest.get_parent().to_local(get_global_mouse_position())
	for object in array:
		var eval_dist = object.position.distance_to(comp_position)
		if eval_dist < closest_dist:
			closest = object
			closest_dist = eval_dist
	return closest

func _on_game_world_we_fight(param):
	if !im_a_slime and param:
		add_to_combat()
	if im_a_slime and fighting and param:
		reset_target_enemy()
	if !param:
		fighting = false

func take_damage(amount):
	if in_main_world:
		health -= amount
		$HPBar.value = health
		GlobalStats.play_sound("Hurt")
		
		taken_damage += amount
		
		var screenshake_mult = 1
		if end_phase == 2:
			screenshake_mult = 4
		
		if health <= 0:
			get_parent().shake_camera(10, 1 * screenshake_mult)
			die()
			schedule_damage_pulse = false
		else:
			get_parent().shake_camera(3, 0.4 * screenshake_mult)
			schedule_damage_pulse = true

func set_health(amount):
	health = amount
	$HPBar.value = health

func set_max_health(amount):
	max_hp = amount
	if $HPBar/HPTexture.modulate == Color.RED:
		$HPBar.max_value = amount

# Called when a unit dies with this enemy as a target
func get_kill(enemy):
	level_up(enemy.level)
	if enemy.has_weapon:
		get_tree().call_group("Players", "gimme_my_weapon", enemy.weapon)
		enemy.clear_weapon()
	if enemy.has_health_pickup:
		set_health(max_hp)
		enemy.clear_weapon()

func gimme_my_weapon(new_weapon):
	if new_weapon.x == player_type and new_weapon.y >= weapon.y:
		set_weapon(new_weapon)

func level_up(levels):
	level += levels
	set_max_health(20 + 5 * level)
	
	create_particle_explosion(Color.SKY_BLUE)
	if !im_a_slime:
		GlobalStats.play_sound("Levelup")
	GlobalStats.play_sound("LevelupLite")
	
	$LevelCurr.text = "Level " + str(level)
	$Levelup.text = "Level " + str(level) + "!"
	
	$Levelup.modulate.a = 1.0
	$Levelup.position.y = 0
	
	var tween_mod = get_tree().create_tween()
	var tween_pos = get_tree().create_tween()
	tween_mod.set_trans(Tween.TRANS_QUINT)
	tween_pos.set_trans(Tween.TRANS_QUINT)
	tween_mod.set_ease(Tween.EASE_OUT)
	tween_pos.set_ease(Tween.EASE_OUT)
	tween_mod.tween_property($Levelup, "modulate:a", 0.0, 2.0)
	tween_pos.tween_property($Levelup, "position:y", -60, 1.0)

func create_damage_text(amount):
	var damage_text = damage_text_object.instantiate()
	damage_text.text = str(amount)
	damage_text.position = position
	get_parent().add_child(damage_text)
	return damage_text

func create_particle_explosion(color):
	var particles = particles_object.instantiate()
	particles.emitting = true
	particles.position = position
	particles.modulate = color
	get_parent().add_child(particles)
	return particles

func swing_weapon():
	if !has_health_pickup:
		var tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		if im_a_slime:
			tween.tween_property($Weapon, "rotation", deg_to_rad(-60), 0.1)
		else:
			tween.tween_property($Weapon, "rotation", deg_to_rad(60), 0.1)
		tween.tween_callback(reset_weapon)

func reset_weapon():
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_CIRC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property($Weapon, "rotation", 0, 0.1)

func die():
	create_particle_explosion(Color.WHITE_SMOKE)
	GlobalStats.play_sound("Death")
	fighting = false
	in_main_world = false
	# Gamers don't die, they respawn
	if !im_a_slime:
		dead = true
		modulate = Color.DIM_GRAY
	else:
		taken_damage = 0
	get_parent().thing_dies(self)

func _on_game_world_combat_tick():
	var damage = level
	if has_weapon:
		damage = level * WEAPON_MULTIPLIERS[weapon.y]
	if fighting:
		swing_weapon()
		target_enemy.take_damage(damage)
	if end_phase == 2:
		if !dead:
			take_damage(DRAGON_DAMAGE)
			get_parent().damage_dragon(damage)

func _on_mouse_shape_entered(_shape_idx):
	$LevelCurr.modulate.a = 0
	$LevelCurr.text = "Level " + str(level)
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_CIRC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($LevelCurr, "modulate:a", 1, 0.2)
	
	if im_a_slime and !ending:
		if !in_main_world and slime_cooldown >= slime_cooldown_max:
			var tween_2 = get_tree().create_tween()
			tween_2.set_trans(Tween.TRANS_QUINT)
			tween_2.set_ease(Tween.EASE_OUT)
			tween_2.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
		
			hovered = true
		releasing = false

func unhover_slime():
	
	var tween_2 = get_tree().create_tween()
	tween_2.set_trans(Tween.TRANS_BOUNCE)
	tween_2.set_ease(Tween.EASE_OUT)
	tween_2.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	hovered = false
	releasing = false

func release_slime():
	$Sprite.play("idle")
	GlobalStats.play_sound("Drop")
	var drop_particles = create_particle_explosion(Color.GRAY)
	Input.set_custom_mouse_cursor(open_mouse)
	
	drop_particles.scale = Vector2(0.6, 0.4)
	drop_particles.modulate.a = 0.1
	
	if !in_main_world:
		var top_half = get_global_mouse_position().y < get_parent().world_thresh.y
		var left_half = get_global_mouse_position().x < get_parent().world_thresh.x
		# If this is in the region of the Gold mining space
		var left_side = get_global_mouse_position().x < get_parent().gold_thresh_x
		
		var past_health = get_global_mouse_position().x > get_parent().health_thresh_x
		var past_barracade = get_global_mouse_position().x > get_parent().barracade_thresh_x
		
		# Real world region
		if top_half and left_half:
			var parent = get_parent()
			parent.remove_child(self)
			parent.get_parent().get_parent().get_node("GameWorld").add_slime(self)
			in_main_world = true
			add_to_world()
			_on_mouse_shape_exited("")
		# Mining region
		elif left_side and !top_half:
			slime_activity = SLIME_ACTIVITIES.MINING
			slime_progress_mining = 0
			toggle_hp_bar_display(true, "mining")
		# Shopping region
		elif top_half and !left_half:
			if !has_health_pickup:
				var shop_item = get_closest_from(get_tree().get_nodes_in_group("ShopItem"))
				if (shop_item.item_type == weapon.x) or !has_weapon:
					var purchased_item = shop_item.land_on_item()
					if typeof(purchased_item) == TYPE_VECTOR2I:
						var particles = create_particle_explosion(Color.GOLDENROD)
						particles.texture = coin_particles
						set_weapon(purchased_item)
				else:
					GlobalStats.play_sound("No")
			else:
				GlobalStats.play_sound("No")
		# Workout region
		elif !top_half and !left_half:
			slime_activity = SLIME_ACTIVITIES.EXERCISE
			slime_progress_exercise = 0
			toggle_hp_bar_display(true, "exercise")
		# Barracade region
		elif past_barracade:
			if GlobalStats.gold >= get_parent().barracade_price:
				get_parent().get_parent().get_parent().get_node("GameWorld").spawn_barracade()
				GlobalStats.add_gold(-get_parent().barracade_price)
				
				get_parent().increment_barracade_price()
			else:
				GlobalStats.play_sound("No")
		# Health region
		elif past_health:
			if !has_weapon and !has_health_pickup and GlobalStats.gold >= get_parent().health_price:
				has_health_pickup = true
				$Weapon.position.x = 34
				$Weapon.animation = "other"
				$Weapon.frame = 2
				var particles = create_particle_explosion(Color.GOLDENROD)
				particles.texture = coin_particles
				GlobalStats.play_sound("Money")
				GlobalStats.add_gold(-get_parent().health_price)
				
				get_parent().increment_health_price()
				
			else:
				GlobalStats.play_sound("No")

func _on_mouse_shape_exited(_shape_idx):
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_CIRC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property($LevelCurr, "modulate:a", 0, 0.2)
	
	if im_a_slime:
		releasing = true

func toggle_hp_bar_display(enable, type=""):
	$HPBar.visible = enable
	$HPEmpty.visible = enable
	match type:
		"health":
			$HPBar/HPTexture.modulate = Color.RED
			$HPBar.max_value = health
			$HPBar.value = health
		"mining":
			$HPBar/HPTexture.modulate = Color.GOLDENROD
			$HPBar.max_value = slime_progress_mining_max
			$HPBar.value = slime_progress_mining
		"exercise":
			$HPBar/HPTexture.modulate = Color.SKY_BLUE
			$HPBar.max_value = slime_progress_exercise_max
			$HPBar.value = slime_progress_exercise
		"cooldown":
			$HPBar/HPTexture.modulate = Color.WHITE
			$HPBar.max_value = slime_cooldown_max
			$HPBar.value = slime_cooldown

func end_cutscene():
	ending = true
	end_phase = 0

func end_charge():
	end_phase = 1

func end_fight():
	end_phase = 2

func set_weapon(item):
	has_weapon = true
	weapon = item
	$Weapon.animation = weapon_types[item.x]
	$Weapon.frame = item.y

func clear_weapon():
	has_health_pickup = false
	has_weapon = false
	$Weapon.position.x = -14
	$Weapon.animation = "other"
	$Weapon.frame = 0

func barracade_pause():
	stopped_for_barracade = true

func barracade_done():
	stopped_for_barracade = false

func barracade_tick():
	if stopped_for_barracade:
		swing_weapon()

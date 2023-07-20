extends Node2D

signal we_fight
signal combat_tick

const DRAGON_HEALTH_MAX = 10000

var cam_offset = 400
var cam_shake_time = 0
var cam_shake_mult = 1

var tracked_players = []
var tracked_slimes = []

var tracked_progress_bar

# Ending stuffs
var ending = false
var ending_step = 0
var dragon_health = DRAGON_HEALTH_MAX

var barracade_scene = preload("res://Objects/barracade.tscn")
var barracade_doing = false

# Called when the node enters the scene tree for the first time.
func _ready():
	GlobalStats.play_music("Game")
	
	cam_offset = $WorldCamera.position.x - $Player.position.x
	tracked_players = get_tree().get_nodes_in_group("Players")
	tracked_slimes = get_tree().get_nodes_in_group("Slimes")
	tracked_progress_bar = %Interface.get_node("ProgressBar")
	tracked_progress_bar.max_value = ($WorldCamera.position + $WorldCamera/EndFinder.position).distance_to($End.position)
	tracked_progress_bar.value = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var new_worldcam_pos = INF
	var living_players = 0
	for player in tracked_players:
		if !player.dead:
			living_players +=1 
			new_worldcam_pos = min(new_worldcam_pos, player.position.x)
	if !ending and living_players > 0:
		$WorldCamera.position.x = new_worldcam_pos + cam_offset
	if cam_shake_time > 0:
		$WorldCamera.offset.x = sin(Time.get_ticks_msec()) * cam_shake_time * cam_shake_mult
		cam_shake_time -= 1
	else:
		$WorldCamera.offset.x = 0
	
	var dist_from_end = ($WorldCamera.position + $WorldCamera/EndFinder.position).distance_to($End.position)
	tracked_progress_bar.value = tracked_progress_bar.max_value - dist_from_end
	var progress_percentage = tracked_progress_bar.value / tracked_progress_bar.max_value
	tracked_progress_bar.self_modulate.g = 1 - progress_percentage
	tracked_progress_bar.self_modulate.b = 1 - progress_percentage
	tracked_progress_bar.get_node("WhiteCircle").self_modulate.g = 1 - progress_percentage
	tracked_progress_bar.get_node("WhiteCircle").self_modulate.b = 1 - progress_percentage
	
	if living_players == 0:
		get_tree().call_group("EndingBackground", "fade_onscreen", false)
	
func _on_combat_zone_body_entered(body):
	if body.im_a_slime and body.in_main_world:
		body.fighting = true
		emit_signal("we_fight", true)
		body.add_to_combat()
		if $CombatTick.is_stopped():
			emit_signal("combat_tick")
			$CombatTick.start()
	if body.im_a_barracade:
		get_tree().call_group("Players", "barracade_pause")
		get_tree().call_group("Slimes", "barracade_pause")
		$BarracadeTick.start()
		barracade_doing = true
		body.active = true
		body.connect("barracade_done", barracade_done)

func _on_barracade_tick_timeout():
	get_tree().call_group("Players", "barracade_tick")
	get_tree().call_group("Barracades", "barracade_tick")
	if !barracade_doing:
		$BarracadeTick.start()

func barracade_done():
	get_tree().call_group("Players", "barracade_done")
	get_tree().call_group("Slimes", "barracade_done")
	barracade_doing = false
	$BarracadeTick.stop()

func _on_combat_tick_timeout():
	emit_signal("combat_tick")
	
func add_slime(slime):
	add_child(slime)
	slime.position = get_local_mouse_position()

func thing_dies(thing):
	if thing.im_a_slime:
		thing.target_enemy.get_kill(thing)
		reset_slime(thing)
	var continue_fight = false
	for slime in tracked_slimes:
		if slime.fighting:
			continue_fight = true
	emit_signal("we_fight", continue_fight)
	

func reset_slime(slime):
	remove_child(slime)
	%Interface.get_node("SlimeLayer").add_child(slime)
	slime.position = slime.hotbar_pos
	slime.set_health(slime.max_hp)
	
	slime.slime_cooldown = 0
	slime.modulate = Color.DIM_GRAY
	slime.get_node("Sprite").speed_scale = 0.6
	
	slime.toggle_hp_bar_display(true, "cooldown")

func shake_camera(time, strength = 1):
	if cam_shake_time > 0:
		cam_shake_mult = max(cam_shake_mult, strength)
	else:
		cam_shake_mult = strength
	cam_shake_time += time

func _on_end_finder_area_entered(area):
	if area == $End:
		get_tree().call_group("Slimes", "end_cutscene")
		get_tree().call_group("Players", "end_cutscene")
		get_tree().call_group("DragonHP", "set_default", DRAGON_HEALTH_MAX)
		ending = true
		ending_step = 0
			
		var tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(tracked_progress_bar, "position:y", tracked_progress_bar.position.y - 100, 0.6)
		
		GlobalStats.fade_out_music()
		$Dragon.play("roar")
		$EndingTimer.wait_time = 0.5
		$EndingTimer.start()

func _on_ending_timer_timeout():
	match(ending_step):
		0:
			GlobalStats.play_sound("DragonRoar")
			$EndingTimer.wait_time = 2
			ending_step += 1
			$EndingTimer.start()
		1:
			get_tree().call_group("Players", "end_charge")
			get_tree().call_group("DragonHP", "fade_onscreen")
			
			var tween = get_tree().create_tween()
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property($Dragon, "position:x", $Dragon.position.x + 500, 2.0)
			
			$EndingTimer.wait_time = 2.5
			ending_step += 1
			$EndingTimer.start()
		2:
			get_tree().call_group("Players", "end_fight")
			$CombatTick.wait_time = 0.25
			$CombatTick.start()

func damage_dragon(amount):
	dragon_health -= amount
	get_tree().call_group("DragonHP", "update_label", dragon_health)
	if dragon_health <= 0:
		GlobalStats.play_sound("Death")
		GlobalStats.play_sound("DragonRoar")
		get_tree().call_group("EndingBackground", "fade_onscreen", true)
		$CombatTick.stop()

func spawn_barracade():
	var barracade = barracade_scene.instantiate()
	barracade.position.x = $WorldCamera/CombatZone.position.x + $WorldCamera.position.x + 200
	barracade.position.y = $WorldCamera/CombatZone.position.y + $WorldCamera.position.y
	add_child(barracade)


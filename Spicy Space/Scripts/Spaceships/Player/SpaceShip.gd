extends Area2D

signal ss_damage(which_pitfall)
signal game_over
signal shoot
signal crate_grabbed(which_crate)
signal hr_situation(situation)
signal mine_grabbed(event)

export var rot_speed = 2
export var thrust = 300
export var friction = 0.65

onready var laser = preload("res://Scenes/Spaceship_,Parts/Lasers/PlayerLaser.tscn")
onready var laser_container = $laser_container
onready var laser_muzzle = $laser_muzzle
onready var shoot_timer = $shoot_timer
onready var hr_followpoint = $HR_FollowPoint # Health robot follow point
onready var sr_followpoint = $SR_FollowPoint # Shield robot follow point
onready var shield = $Shield

var screen_size = Vector2()
var rot = 0
var pos = Vector2()
var vel = Vector2()
var acc = Vector2()
var explode_control = false
var robots = [] # spaceship's robots
var out_of_ammo_control = false
var shoot_control = false

func _ready():
	reload_spaceship()
	randomize()
	rot = rand_range(0, 90) #random rotation degree
	screen_size = get_viewport_rect().size
	centered_position()
	set_process(true)
	explode_control = false

func _process(delta):
	if explode_control == false: # if ss exploded
		_move(delta)
		_shoot(delta)

	_stay_on_screen(delta) 

func centered_position():
	pos = screen_size / 2
	self.position = pos

func reload_spaceship():
	shoot_timer.wait_time = Global.ship_datas.get("shoot_rate")

func _move(delta):
	#move
	if Input.is_action_pressed("ui_up"):
		acc = Vector2(-thrust, 0).rotated(rot)
	else:
		acc = Vector2(0, 0)
	if Input.is_action_pressed("ui_right"):
		rot += rot_speed * delta
	if Input.is_action_pressed("ui_left"):
		rot -= rot_speed * delta
	_robots_mode("rotate") #rotate robots according to spaceship

func _shoot(delta):
	if shoot_control:
		if shoot_timer.get_time_left() == 0 and explode_control == false:
			_start_shooting()

func _start_shooting():
	SFXManager.player_shoot.play()
	shoot_timer.start()
	var ins_laser = laser.instance()
	laser_container.add_child(ins_laser)
	ins_laser.start_at(self.rotation, laser_muzzle.global_position, vel)
	emit_signal("shoot")

func _stay_on_screen(delta):
	acc += vel * -friction
	vel += acc * delta
	pos += vel * delta
	#stay on screen
	if pos.x > screen_size.x:
		pos.x = 0
	if pos.x < 0:
		pos.x = screen_size.x
	if pos.y > screen_size.y:
		pos.y = 0
	if pos.y < 0:
		pos.y = screen_size.y
	#detect pos and rot
	self.position = pos
	self.rotation = rot - PI/2

func _on_SpaceShip_body_entered(body): #when any collide happen with kinematic or rigidbody
	if body.is_in_group("asteroid"): #when asteroid hit spaceship
		body.explode(body.vel) #explode asteroid
#		print("asteroid dur: " + str(body.ast_dur))
		emit_signal("ss_damage", body.ast_dur) #spaceship got damage from asteroid

func _on_SpaceShip_area_entered(area): #when any collide happen with area
	if area.is_in_group("health_crate"):
		if get_parent().ins_hr.robot_charge_control():
			SFXManager.health_crate.play()
			emit_signal("crate_grabbed", "health_crate")
			area.remove_crate()
	if area.is_in_group("shield_crate"):
		if get_parent().ins_sr.robot_charge_control():
			SFXManager.shield_crate.play()
			emit_signal("crate_grabbed", "shield_crate")
			emit_signal("hr_situation", false) #deactivate health robot if it was active
			ss_shield_deactivate(false) #activate shield if it was deactive
			area.remove_crate()
	if area.is_in_group("mine_crate"):
		SFXManager.collect_mine.play()
		Global.mine += randi() % 20 + 5 
		area.remove_crate()
	if area.is_in_group("enemy_laser"):
		emit_signal("ss_damage", area.laser_damage) #spaceship got damage from enemy
	if area.is_in_group("mine"):
		SFXManager.collect_mine.play()
		emit_signal("mine_grabbed", "collect")
		area.remove_mine()
	if area.is_in_group("bomb"):
		SFXManager.bomb.play()
		print("bomb exploded!")
		emit_signal("ss_damage", 3)
		area.call_deferred("free")

func ss_shield_deactivate(situation): #spaceship shield deactivate or not
	if situation == false: #don't deactive
		shield.show()
	else: #deactive
		shield.hide()

func ss_explode():
	SFXManager.ship_explosion.play()
	EffectManager.explosion_effect(self.position)
	explode_control = true
	self.visible = false
	self.call_deferred("set_monitoring", false)
	emit_signal("game_over")
	_robots_mode("explode") # explode all robots too

func _robots_mode(mode):
	for r in robots: 
		if mode == "explode":
			r.explode_robot()
		if mode == "rotate":
			r.rot_deg = self.rotation_degrees


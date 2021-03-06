extends KinematicBody2D

signal ast_exploded(pos)
signal ast_split(ast_size, ast_scale, pos, vel, hit_vel)

export (int) var number_of_ast = 5
export (int) var min_speed = 50
export (int) var max_speed = 350
export (float) var min_scale = 0.6
export (float) var max_scale = 2

onready var ast_sprite = $asteroid_sprite
onready var ast_coll = $asteroid_coll
onready var puff_effect = $puff_particle

var vel = Vector2()
var rand_scale
var rot_speed
var screen_size
var extents
var ast_dur = 1 #asteroid durability

func _ready():
	randomize()
	_rand_scale()
	set_physics_process(true)
	#velocity
	vel = Vector2(rand_range(min_speed, max_speed), 0).rotated(rand_range(0, 2 * PI))
	#rotation
	rot_speed = rand_range(-1.5, 1.5)
	#screen border
	screen_size = get_viewport_rect().size
	extents = ast_sprite.get_texture().get_size() / 2
	_choose_asteroid(number_of_ast)

func _physics_process(delta):
	self.rotation =  self.rotation + rot_speed * delta
	var collide = move_and_collide(delta * vel)
	if collide:
		vel = vel.bounce(collide.normal)

	# wrap around screen edges
	var pos = self.position
	if pos.x > screen_size.x + extents.x:
		pos.x = -extents.x
	if pos.x < -extents.x:
		pos.x = screen_size.x + extents.x
	if pos.y > screen_size.y + extents.y:
		pos.y = -extents.y
	if pos.y < -extents.y:
		pos.y = screen_size.y + extents.y
	self.position = pos

func _rand_scale():
	#random scale
	rand_scale = rand_range(min_scale, max_scale)
	var rand_vector = Vector2(rand_scale, rand_scale)
	scale = rand_vector

func _choose_asteroid(number_of_ast):
	var frame = 0
	var rand_frames = []
	
	for counter in range(number_of_ast):
		rand_frames.append(frame)
		frame += 32
		
	#choose random asteroid texture
	randomize()
	var rand_frame = rand_frames[randi()%rand_frames.size()]
	ast_sprite.region_rect.position.y = rand_frame
	
	#add collision shape according to asteroid texture's size
	var shape = CircleShape2D.new()
	shape.set_radius(min(ast_sprite.texture.get_width()/2, ast_sprite.texture.get_height()/2))
	ast_coll.shape = shape

func explode(hit_vel):
	SFXManager.asteroid.play()
	if self.scale.x * 0.5 > min_scale:
		emit_signal("ast_split", 'big', self.scale, self.position, vel, hit_vel)
	emit_signal("ast_exploded", self.position)
	call_deferred("free")
	Global.score += 2 #increase score

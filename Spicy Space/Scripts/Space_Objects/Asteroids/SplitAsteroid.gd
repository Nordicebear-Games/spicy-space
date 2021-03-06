extends KinematicBody2D

signal ast_exploded(pos)
signal ast_split(ast_size, pos, vel, hit_vel)

export (int) var number_of_ast = 5
export (int) var min_speed = 30
export (int) var max_speed = 280

onready var ast_sprite = $asteroid_sprite
onready var ast_coll = $asteroid_coll

var vel = Vector2()
var rot_speed
var screen_size
var extents
var ast_dur = 1

func init(init_size, init_scale, init_pos, init_vel):
	#scale
	if init_size == 'med':
		scale = init_scale / 2
	#velocity
	if init_vel.length() > 0:
		self.vel = init_vel
	else:
		vel = Vector2(rand_range(30, 100), 0).rotated(rand_range(0, 2*PI))
	#position
	self.position = init_pos

func _ready():
	set_physics_process(true)
	randomize()
	vel = Vector2(rand_range(min_speed, max_speed), 0).rotated(rand_range(0, 2 * PI))
	rot_speed = rand_range(-1.5, 1.5)
#	ast_dur = randi()% Global.wave + 1
	screen_size = get_viewport_rect().size
	extents = ast_sprite.get_texture().get_size() / 2
	_choose_asteroid(number_of_ast)

func _physics_process(delta):
	vel = vel.clamped(300)
	self.rotation =  self.rotation + rot_speed * delta
	var collide = move_and_collide(delta * vel)
	if collide:
		vel = vel.bounce(collide.normal)
		# puff effect
#		puff_effect.global_position = collide.position
#		puff_effect.emitting = true

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
	emit_signal("ast_split", 'med', self.scale, self.position, vel, hit_vel)
	emit_signal("ast_exploded", self.position)
	call_deferred("free")
	Global.score += 10 #increase score

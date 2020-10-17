extends Node2D

export (bool) var reset_userdata = false
export(PackedScene) var start_mode
export(Array, PackedScene) var game_modes

#Game
onready var game = $Game
#roadmap
onready var roadmap = $Roadmap

func _ready():
	#reset highscore
	if reset_userdata == true:
		UserDataManager.reset_userdata()
	#reset score after every new start
	Global.score = 0

func prepare_game_mode(mode):
	roadmap.visible = false
	game.visible = true
	var ins_game_mode
	if mode == "start":
		ins_game_mode = start_mode.instance()
	elif mode == "meteor shower":
		ins_game_mode = game_modes[0].instance()
	elif mode == "dog fight":
		ins_game_mode = game_modes[1].instance()
	elif mode == "random":
		ins_game_mode = game_modes[randi()% game_modes.size()].instance()
	add_child(ins_game_mode)
	ins_game_mode.spaceship = game.spaceship
	ins_game_mode.hud = game.hud
	ins_game_mode.connect("mode_completed", self, "go_back_to_roadmap")

func go_back_to_roadmap():
	game.visible = false
	roadmap.visible = true


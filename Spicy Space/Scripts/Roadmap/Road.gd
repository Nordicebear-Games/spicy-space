extends Node2D

export(bool) var mode_completed = false
export(bool) var skipped = false
export(Global.game_mode) var game_mode
export(Global.difficulty) var difficulty

onready var button = $Button
onready var info_card = $Info_Card

func _ready():
	if mode_completed:
		button.modulate = Color.green
	if skipped:
		button.disabled = true

func road(status):
	if status == "activate":
		button.disabled = false
	elif status == "deactivate":
		button.disabled = true
	elif status == "skipped":
		skipped = true
		button.disabled = true

func go_to_road(difficulty):
		mode_completed = true
		button.modulate = Color.green
		get_tree().get_root().get_node("Game_Scene").prepare_game_mode(game_mode, difficulty)

func _on_Button_pressed():
	if !mode_completed:
		SFXManager.button.play()
		info_card.show_card(game_mode, difficulty)
	else:
		print("this level already completed")

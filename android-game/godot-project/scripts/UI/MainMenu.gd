extends Control
# Main menu

func _ready():
	# Check if save exists to enable/disable continue button
	check_save_exists()

func check_save_exists():
	var save_file = FileAccess.open("user://save_game.dat", FileAccess.READ)
	if not save_file:
		$MenuButtons/ContinueButton.disabled = true
	else:
		save_file.close()

func _on_new_game_pressed():
	# Show character selection
	show_character_select()

func show_character_select():
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Choose your character:"

	var vbox = VBoxContainer.new()

	var boy_button = Button.new()
	boy_button.text = "Boy"
	boy_button.pressed.connect(func(): start_new_game("boy"))

	var girl_button = Button.new()
	girl_button.text = "Girl"
	girl_button.pressed.connect(func(): start_new_game("girl"))

	vbox.add_child(boy_button)
	vbox.add_child(girl_button)

	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered()

func start_new_game(gender: String):
	# Reset game state
	GameState.player_gender = gender
	GameState.current_stage = 1
	GameState.lives = 3
	GameState.rescued_relatives = []
	GameState.unlocked_powers = []
	GameState.save_game()

	# Load first stage
	get_tree().change_scene_to_file("res://scenes/game_level.tscn")

func _on_continue_pressed():
	# Load saved game
	GameState.load_game()
	get_tree().change_scene_to_file("res://scenes/game_level.tscn")

func _on_leaderboard_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/leaderboard.tscn")

func _on_shop_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/shop.tscn")

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")

func _on_quit_pressed():
	get_tree().quit()

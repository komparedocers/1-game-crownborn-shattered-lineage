extends Node
# Global game state manager

signal relative_saved(relative_name: String)
signal lives_changed(new_lives: int)
signal currency_changed(new_amount: int)
signal power_unlocked(power_name: String)

# Player state
var player_gender: String = "boy"  # "boy" or "girl"
var display_name: String = ""
var lives: int = 3
var max_lives: int = 3

# Progress
var current_stage: int = 1
var rescued_relatives: Array[String] = []
var unlocked_powers: Array[String] = []

# Economy
var sky_crowns: int = 0
var inventory: Dictionary = {}

# User info
var user_id: String = ""
var country_code: String = "US"
var jwt_token: String = ""

func _ready():
	load_game()

func add_currency(amount: int):
	sky_crowns += amount
	currency_changed.emit(sky_crowns)
	save_game()

func spend_currency(amount: int) -> bool:
	if sky_crowns >= amount:
		sky_crowns -= amount
		currency_changed.emit(sky_crowns)
		save_game()
		return true
	return false

func unlock_power(power_name: String):
	if power_name not in unlocked_powers:
		unlocked_powers.append(power_name)
		power_unlocked.emit(power_name)
		save_game()

func rescue_relative(relative_name: String):
	if relative_name not in rescued_relatives:
		rescued_relatives.append(relative_name)
		relative_saved.emit(relative_name)
		save_game()

func lose_life():
	lives -= 1
	lives_changed.emit(lives)

	if lives <= 0:
		# Game over - reset to stage 1
		reset_run()

func add_life():
	if lives < max_lives:
		lives += 1
		lives_changed.emit(lives)

func reset_run():
	lives = 3
	current_stage = 1
	# Keep unlocked powers and rescued relatives (hard unlocks)
	save_game()

func save_game():
	var save_data = {
		"player_gender": player_gender,
		"display_name": display_name,
		"lives": lives,
		"current_stage": current_stage,
		"rescued_relatives": rescued_relatives,
		"unlocked_powers": unlocked_powers,
		"sky_crowns": sky_crowns,
		"inventory": inventory,
		"user_id": user_id,
		"country_code": country_code,
		"jwt_token": jwt_token
	}

	var file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_game():
	var file = FileAccess.open("user://save_game.dat", FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()

		if save_data:
			player_gender = save_data.get("player_gender", "boy")
			display_name = save_data.get("display_name", "")
			lives = save_data.get("lives", 3)
			current_stage = save_data.get("current_stage", 1)
			rescued_relatives = save_data.get("rescued_relatives", [])
			unlocked_powers = save_data.get("unlocked_powers", [])
			sky_crowns = save_data.get("sky_crowns", 0)
			inventory = save_data.get("inventory", {})
			user_id = save_data.get("user_id", "")
			country_code = save_data.get("country_code", "US")
			jwt_token = save_data.get("jwt_token", "")

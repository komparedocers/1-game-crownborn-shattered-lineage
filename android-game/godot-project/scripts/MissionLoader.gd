extends Node
# Loads and manages mission data

var missions_boy: Array = []
var missions_girl: Array = []
var current_mission: Dictionary = {}

func _ready():
	load_missions()

func load_missions():
	# Load boy missions
	var boy_file = FileAccess.open("res://data/missions_boy.json", FileAccess.READ)
	if boy_file:
		var json = JSON.new()
		json.parse(boy_file.get_as_text())
		var data = json.get_data()
		missions_boy = data.get("missions", [])
		boy_file.close()

	# Load girl missions
	var girl_file = FileAccess.open("res://data/missions_girl.json", FileAccess.READ)
	if girl_file:
		var json = JSON.new()
		json.parse(girl_file.get_as_text())
		var data = json.get_data()
		missions_girl = data.get("missions", [])
		girl_file.close()

	print("Loaded ", missions_boy.size(), " boy missions and ", missions_girl.size(), " girl missions")

func get_mission(stage: int) -> Dictionary:
	var missions = missions_boy if GameState.player_gender == "boy" else missions_girl

	for mission in missions:
		if mission.get("id", 0) == stage:
			return mission

	return {}

func load_stage(stage: int):
	current_mission = get_mission(stage)

	if current_mission.is_empty():
		print("ERROR: Mission ", stage, " not found!")
		return

	print("Loading stage ", stage, ": ", current_mission.get("location", "Unknown"))

	# Set up level based on mission data
	setup_level()

func setup_level():
	# Create level based on mission data
	var location = current_mission.get("location", "")
	var enemies = current_mission.get("enemies", [])
	var boss = current_mission.get("boss", {})
	var map_features = current_mission.get("mission", {}).get("mapFeatures", "")

	# Spawn enemies
	spawn_enemies(enemies)

	# Create boss
	spawn_boss(boss)

	# Generate map features (vents, sewers, etc.)
	generate_map_features(map_features)

func spawn_enemies(enemy_types: Array):
	# Spawn enemies in the level
	var spawn_points = get_tree().get_nodes_in_group("spawn_points")

	for i in range(min(enemy_types.size() * 3, spawn_points.size())):
		var enemy_type = enemy_types[i % enemy_types.size()]
		var spawn_point = spawn_points[i]

		var enemy = create_enemy(enemy_type)
		if enemy:
			get_tree().current_scene.add_child(enemy)
			enemy.global_position = spawn_point.global_position

func spawn_boss(boss_data: Dictionary):
	var boss_name = boss_data.get("name", "Unknown Boss")
	var weakness = boss_data.get("weakness", "none")

	# Create boss
	var boss_scene = preload("res://scenes/boss.tscn")
	var boss = boss_scene.instantiate()
	boss.boss_name = boss_name
	boss.weakness = weakness

	# Place at boss spawn point
	var boss_spawn = get_tree().get_first_node_in_group("boss_spawn")
	if boss_spawn:
		get_tree().current_scene.add_child(boss)
		boss.global_position = boss_spawn.global_position

	boss.boss_defeated.connect(_on_boss_defeated)

func create_enemy(type: String) -> CharacterBody3D:
	var enemy_scene = preload("res://scenes/enemy.tscn")
	var enemy = enemy_scene.instantiate()
	enemy.enemy_type = type.to_lower()

	# Configure based on type
	match type.to_lower():
		"wolf", "bear", "eagle":
			enemy.max_health = 30.0
			enemy.damage = 15.0
			enemy.move_speed = 4.0
		"soldier", "archer", "guard":
			enemy.max_health = 50.0
			enemy.damage = 20.0
			enemy.move_speed = 3.0
		"elite", "captain":
			enemy.max_health = 100.0
			enemy.damage = 35.0
			enemy.move_speed = 3.5

	return enemy

func generate_map_features(features: String):
	# Generate secret doors, vents, etc.
	# This would use procedural generation based on the feature description
	pass

func _on_boss_defeated():
	# Boss defeated - complete mission
	complete_mission()

func complete_mission():
	var stage = current_mission.get("id", 0)
	var relative = current_mission.get("relative", {})
	var power = current_mission.get("rewards", {}).get("powerUnlocked", "")

	# Rescue relative
	var relative_name = relative.get("name", "Unknown")
	GameState.rescue_relative(relative_name)

	# Unlock power
	if power:
		GameState.unlock_power(power)

	# Grant currency
	var sc_reward = calculate_reward(stage)
	GameState.add_currency(sc_reward)

	# Submit to server
	var time_ms = Time.get_ticks_msec()  # Would track actual mission time
	NetClient.submit_stage_completion(stage, time_ms, 0, 3, true)

	# Move to next stage
	GameState.current_stage = stage + 1
	GameState.save_game()

	# Show completion screen
	show_mission_complete(relative_name, power, sc_reward)

func calculate_reward(stage: int) -> int:
	return int(50 + stage * 1.3)

func show_mission_complete(relative_name: String, power: String, sc: int):
	print("Mission Complete!")
	print("Rescued: ", relative_name)
	if power:
		print("Unlocked Power: ", power)
	print("Earned: ", sc, " SC")

	# This would show UI
	get_tree().call_deferred("change_scene_to_file", "res://scenes/mission_complete.tscn")

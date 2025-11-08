extends CharacterBody3D
# Boss enemy with weakness mechanics

@export var boss_name: String = "General Krath"
@export var max_health: float = 500.0
@export var weakness: String = "ground"  # ground, mirror, interrupt, etc.
@export var phase_count: int = 3

var current_health: float
var current_phase: int = 1
var is_vulnerable: bool = false
var player: Node3D

@onready var animation_player = $AnimationPlayer

signal boss_defeated
signal phase_changed(new_phase: int)
signal weakness_exposed

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Boss AI based on current phase
	match current_phase:
		1:
			phase_one_behavior(delta)
		2:
			phase_two_behavior(delta)
		3:
			phase_three_behavior(delta)

	move_and_slide()

func phase_one_behavior(delta):
	# Basic attacks
	if player:
		var distance = global_position.distance_to(player.global_position)

		if distance > 5.0:
			# Move towards player
			var direction = (player.global_position - global_position).normalized()
			velocity.x = direction.x * 4.0
			velocity.z = direction.z * 4.0
		else:
			# Attack
			velocity.x = 0
			velocity.z = 0
			perform_basic_attack()

func phase_two_behavior(delta):
	# More aggressive with special attacks
	if player:
		var distance = global_position.distance_to(player.global_position)

		if distance > 8.0:
			# Charge attack
			var direction = (player.global_position - global_position).normalized()
			velocity.x = direction.x * 8.0
			velocity.z = direction.z * 8.0
		else:
			# Area attack
			velocity.x = 0
			velocity.z = 0
			perform_area_attack()

func phase_three_behavior(delta):
	# Final desperate phase
	# Expose weakness more frequently
	is_vulnerable = true
	weakness_exposed.emit()

	if player:
		# Alternating attacks
		if randf() < 0.5:
			perform_special_attack()
		else:
			perform_area_attack()

func perform_basic_attack():
	if animation_player:
		animation_player.play("basic_attack")

	if player and player.has_method("take_damage"):
		player.take_damage(30.0)

func perform_area_attack():
	if animation_player:
		animation_player.play("area_attack")

	# Damage all nearby players
	var bodies = $AttackArea.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(50.0)

func perform_special_attack():
	# Boss-specific attack based on weakness
	match weakness:
		"ground":
			# Flying attack - vulnerable when grounded
			jump_attack()
		"mirror":
			# Can only be damaged when approached unseen
			mirror_defense()
		"interrupt":
			# Chanting - must be interrupted
			channeling_attack()

func jump_attack():
	velocity.y = 15.0
	is_vulnerable = false

	# When lands, becomes vulnerable
	await get_tree().create_timer(2.0).timeout
	if is_on_floor():
		is_vulnerable = true
		weakness_exposed.emit()

func mirror_defense():
	# Creates illusions
	is_vulnerable = false

	# Vulnerable when player is in stealth
	if player and player.modulate.a < 0.5:  # Player is in stealth
		is_vulnerable = true
		weakness_exposed.emit()

func channeling_attack():
	is_vulnerable = false

	if animation_player:
		animation_player.play("channel")

	# If interrupted by damage during channel, becomes vulnerable
	await get_tree().create_timer(3.0).timeout

	if current_health == current_health:  # Not damaged during channel
		# Release powerful attack
		perform_area_attack()
	else:
		# Interrupted
		is_vulnerable = true
		weakness_exposed.emit()

func take_damage(amount: float):
	# Check if boss is vulnerable or being hit at weakness
	var damage_multiplier = 1.0

	if is_vulnerable:
		damage_multiplier = 2.0  # Double damage when vulnerable

	current_health -= amount * damage_multiplier

	# Phase transitions
	var health_percentage = current_health / max_health

	if health_percentage <= 0.66 and current_phase == 1:
		enter_phase(2)
	elif health_percentage <= 0.33 and current_phase == 2:
		enter_phase(3)

	if current_health <= 0:
		die()

func enter_phase(new_phase: int):
	current_phase = new_phase
	phase_changed.emit(current_phase)

	# Heal slightly between phases
	current_health += max_health * 0.1

	print("Boss entered phase ", new_phase)

func die():
	boss_defeated.emit()

	# Grant rewards
	GameState.add_currency(400)  # Boss bonus

	# Play death animation
	if animation_player:
		animation_player.play("death")

	await get_tree().create_timer(2.0).timeout
	queue_free()

func get_weakness_hint() -> String:
	# Return hint for Shaman
	match weakness:
		"ground":
			return "Lightning farms crown the cliffs; bring the storm to earth."
		"mirror":
			return "Mirror angles show what she cannot see; approach unseen."
		"interrupt":
			return "He chants so he cannot listen; speak with force."
		_:
			return "Every fortress has a forgotten vein; feel for its pulse."

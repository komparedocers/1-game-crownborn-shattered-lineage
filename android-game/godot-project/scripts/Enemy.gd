extends CharacterBody3D
# Base enemy class

enum State {
	IDLE,
	PATROL,
	SEARCH,
	ATTACK,
	FLEE
}

@export var enemy_type: String = "soldier"  # animal, soldier, elite
@export var max_health: float = 50.0
@export var damage: float = 10.0
@export var move_speed: float = 3.0
@export var detection_range: float = 15.0
@export var attack_range: float = 2.0

var current_health: float
var current_state: State = State.PATROL
var player: Node3D
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0
var time_since_last_attack: float = 0.0
var attack_cooldown: float = 2.0

@onready var navigation_agent = $NavigationAgent3D
@onready var detection_area = $DetectionArea
@onready var animation_player = $AnimationPlayer

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")

	# Setup detection
	if detection_area:
		detection_area.body_entered.connect(_on_player_detected)
		detection_area.body_exited.connect(_on_player_lost)

	# Generate patrol points
	generate_patrol_points()

func _physics_process(delta):
	time_since_last_attack += delta

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	match current_state:
		State.IDLE:
			idle_behavior(delta)
		State.PATROL:
			patrol_behavior(delta)
		State.SEARCH:
			search_behavior(delta)
		State.ATTACK:
			attack_behavior(delta)
		State.FLEE:
			flee_behavior(delta)

	move_and_slide()

func idle_behavior(delta):
	velocity.x = 0
	velocity.z = 0

	# Check for player
	if player and global_position.distance_to(player.global_position) < detection_range:
		current_state = State.ATTACK

func patrol_behavior(delta):
	if patrol_points.is_empty():
		current_state = State.IDLE
		return

	var target = patrol_points[current_patrol_index]
	var direction = (target - global_position).normalized()

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	# Check if reached patrol point
	if global_position.distance_to(target) < 1.0:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()

	# Check for player
	if player and global_position.distance_to(player.global_position) < detection_range:
		current_state = State.ATTACK

func search_behavior(delta):
	# Look for player
	if player and global_position.distance_to(player.global_position) < detection_range:
		current_state = State.ATTACK
	else:
		await get_tree().create_timer(3.0).timeout
		current_state = State.PATROL

func attack_behavior(delta):
	if not player:
		current_state = State.SEARCH
		return

	var distance = global_position.distance_to(player.global_position)

	if distance > detection_range:
		current_state = State.SEARCH
		return

	# Move towards player
	if distance > attack_range:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		# In attack range
		velocity.x = 0
		velocity.z = 0

		if time_since_last_attack >= attack_cooldown:
			perform_attack()
			time_since_last_attack = 0.0

	# Low health - flee
	if current_health < max_health * 0.3:
		current_state = State.FLEE

func flee_behavior(delta):
	if not player:
		current_state = State.PATROL
		return

	# Run away from player
	var direction = (global_position - player.global_position).normalized()
	velocity.x = direction.x * move_speed * 1.5
	velocity.z = direction.z * move_speed * 1.5

func perform_attack():
	if player and player.has_method("take_damage"):
		player.take_damage(damage)

	if animation_player:
		animation_player.play("attack")

func take_damage(amount: float):
	current_health -= amount

	# Alert nearby enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy != self and global_position.distance_to(enemy.global_position) < 20.0:
			enemy.alert(player.global_position)

	if current_health <= 0:
		die()
	else:
		current_state = State.ATTACK

func die():
	# Drop loot
	drop_loot()

	# Remove from scene
	queue_free()

func drop_loot():
	# Random chance to drop currency
	if randf() < 0.7:
		var amount = randi_range(5, 20)
		GameState.add_currency(amount)

func alert(position: Vector3):
	current_state = State.ATTACK

func generate_patrol_points():
	# Generate random patrol points in area
	for i in range(3):
		var offset = Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
		patrol_points.append(global_position + offset)

func _on_player_detected(body):
	if body.is_in_group("player"):
		current_state = State.ATTACK

func _on_player_lost(body):
	if body.is_in_group("player"):
		current_state = State.SEARCH

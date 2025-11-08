extends CharacterBody3D
# Main player controller

@export var move_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

# Combat
var max_health: float = 100.0
var current_health: float = 100.0
var is_attacking: bool = false
var attack_damage: float = 25.0

# Inventory
var has_sword: bool = true
var has_knife: bool = true
var has_auto_bow: bool = true
var arrow_count: int = 30

# Powers - unlocked through gameplay
var active_powers: Dictionary = {}

# References
@onready var camera = $Camera3D
@onready var animation_player = $AnimationPlayer

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Load unlocked powers from GameState
	for power in GameState.unlocked_powers:
		unlock_power(power)

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var current_speed = sprint_speed if Input.is_action_pressed("sprint") else move_speed

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

func _input(event):
	# Camera rotation (for mobile, this would use virtual joystick)
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	# Combat
	if event.is_action_pressed("attack"):
		perform_attack()

	if event.is_action_pressed("special"):
		use_special_attack()

	# Powers
	if event.is_action_pressed("rub_ring"):
		summon_shaman()

func perform_attack():
	if is_attacking:
		return

	is_attacking = true

	# Raycast for hit detection
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_transform.basis.z * 3.0)

	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result:
		var target = result.collider
		if target.has_method("take_damage"):
			target.take_damage(attack_damage)

	# Animation
	if animation_player:
		animation_player.play("attack_sword")

	await get_tree().create_timer(0.5).timeout
	is_attacking = false

func use_special_attack():
	if arrow_count > 0:
		arrow_count -= 1
		fire_auto_bow()

func fire_auto_bow():
	# Multi-burst arrows
	for i in range(3):
		spawn_arrow(i * 0.1)

func spawn_arrow(delay: float):
	await get_tree().create_timer(delay).timeout

	var arrow = preload("res://scenes/arrow.tscn").instantiate()
	get_parent().add_child(arrow)
	arrow.global_position = camera.global_position
	arrow.global_rotation = camera.global_rotation
	arrow.velocity = -camera.global_transform.basis.z * 20.0

func take_damage(amount: float):
	current_health -= amount

	if current_health <= 0:
		die()

func die():
	GameState.lose_life()
	# Reset to checkpoint or respawn

func heal(amount: float):
	current_health = min(current_health + amount, max_health)

# Powers
func unlock_power(power_name: String):
	active_powers[power_name] = true

func use_power(power_name: String):
	if not active_powers.get(power_name, false):
		return

	match power_name:
		"Blink Step":
			blink_step()
		"Shadow Veil":
			shadow_veil()
		"Time Slip":
			time_slip()
		"Aerial Glide":
			aerial_glide()
		"Stoneguard":
			stoneguard()

func blink_step():
	# Short-range teleport
	var forward = -transform.basis.z * 5.0
	position += forward

func shadow_veil():
	# Become invisible for 5 seconds
	modulate.a = 0.3
	await get_tree().create_timer(5.0).timeout
	modulate.a = 1.0

func time_slip():
	# Slow down time for 3 seconds
	Engine.time_scale = 0.5
	await get_tree().create_timer(3.0).timeout
	Engine.time_scale = 1.0

func aerial_glide():
	# Slow fall
	gravity = 2.0
	await get_tree().create_timer(5.0).timeout
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func stoneguard():
	# Temporary invulnerability
	max_health *= 2.0
	await get_tree().create_timer(10.0).timeout
	max_health /= 2.0

func summon_shaman():
	# Show shaman guidance UI
	get_node("/root/Main/UI").show_shaman_wisdom()

extends Node3D
# Procedural level generator for missions

@export var level_size: Vector2 = Vector2(50, 50)
@export var building_count: int = 5

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()

func generate_level(mission_data: Dictionary):
	"""Generate a level based on mission data"""
	clear_level()

	var location = mission_data.get("location", "")
	var map_features = mission_data.get("mission", {}).get("mapFeatures", "")

	# Generate base terrain
	generate_terrain()

	# Generate buildings/structures
	generate_structures(building_count)

	# Add secret passages based on map features
	generate_secret_passages(map_features)

	# Add environmental details
	generate_environment(location)

func clear_level():
	# Remove all dynamic objects
	for child in get_children():
		if child.is_in_group("dynamic"):
			child.queue_free()

func generate_terrain():
	"""Generate base ground plane"""
	var ground = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = level_size

	ground.mesh = plane_mesh
	add_child(ground)
	ground.add_to_group("dynamic")

func generate_structures(count: int):
	"""Generate buildings and bases"""
	for i in range(count):
		var building = create_building()
		add_child(building)
		building.add_to_group("dynamic")

		# Random position
		var pos = Vector3(
			rng.randf_range(-level_size.x / 2, level_size.x / 2),
			0,
			rng.randf_range(-level_size.y / 2, level_size.y / 2)
		)
		building.position = pos

func create_building() -> Node3D:
	"""Create a simple building structure"""
	var building = Node3D.new()

	# Main building mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(
		rng.randf_range(5, 10),
		rng.randf_range(3, 8),
		rng.randf_range(5, 10)
	)
	mesh_instance.mesh = box_mesh

	# Add collision
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = box_mesh.size
	collision_shape.shape = shape

	static_body.add_child(collision_shape)
	building.add_child(mesh_instance)
	building.add_child(static_body)

	# Add doors
	add_doors(building, box_mesh.size)

	return building

func add_doors(building: Node3D, size: Vector3):
	"""Add entry points to building"""
	# Front door
	var door_marker = Marker3D.new()
	door_marker.position = Vector3(0, 0, size.z / 2)
	door_marker.add_to_group("doors")
	building.add_child(door_marker)

	# Back door
	var back_door = Marker3D.new()
	back_door.position = Vector3(0, 0, -size.z / 2)
	back_door.add_to_group("doors")
	building.add_child(back_door)

func generate_secret_passages(features: String):
	"""Generate secret doors, vents, sewers based on mission features"""
	if "vent" in features.to_lower():
		create_vent_system()

	if "sewer" in features.to_lower():
		create_sewer_entrance()

	if "rafter" in features.to_lower():
		create_rafters()

	if "ivy" in features.to_lower():
		create_climbable_ivy()

	if "chimney" in features.to_lower():
		create_chimney_entrance()

func create_vent_system():
	"""Create ventilation shaft entrance"""
	var vent = Area3D.new()
	vent.add_to_group("secret_passage")
	vent.position = Vector3(rng.randf_range(-20, 20), 0, rng.randf_range(-20, 20))
	add_child(vent)

func create_sewer_entrance():
	"""Create sewer system entrance"""
	var sewer = Area3D.new()
	sewer.add_to_group("secret_passage")
	sewer.position = Vector3(rng.randf_range(-20, 20), -1, rng.randf_range(-20, 20))
	add_child(sewer)

func create_rafters():
	"""Create high rafters for traversal"""
	var rafter = Node3D.new()
	rafter.position = Vector3(0, 5, 0)
	rafter.add_to_group("high_ground")
	add_child(rafter)

func create_climbable_ivy():
	"""Create ivy for wall climbing"""
	var ivy = Area3D.new()
	ivy.add_to_group("climbable")
	add_child(ivy)

func create_chimney_entrance():
	"""Create chimney entrance"""
	var chimney = Area3D.new()
	chimney.add_to_group("secret_passage")
	chimney.position = Vector3(rng.randf_range(-20, 20), 3, rng.randf_range(-20, 20))
	add_child(chimney)

func generate_environment(location: String):
	"""Add environmental details based on location"""
	match location.to_lower():
		"ashenport":
			add_docks_environment()
		"obsidian bazaar":
			add_market_environment()
		"stormglass keep":
			add_lightning_environment()
		"whispering marsh":
			add_marsh_environment()
		_:
			add_generic_environment()

func add_docks_environment():
	"""Add dock-specific details"""
	# Add water, crates, ships
	pass

func add_market_environment():
	"""Add market stalls and crowds"""
	# Add stalls, NPCs
	pass

func add_lightning_environment():
	"""Add lightning effects"""
	# Add storm particles
	pass

func add_marsh_environment():
	"""Add marsh fog and vegetation"""
	# Add fog, reeds
	pass

func add_generic_environment():
	"""Add generic environment details"""
	# Add basic vegetation, rocks
	pass

func get_spawn_points() -> Array[Vector3]:
	"""Get valid enemy spawn points"""
	var spawn_points: Array[Vector3] = []

	# Generate random spawn points away from player start
	for i in range(10):
		var point = Vector3(
			rng.randf_range(-level_size.x / 2, level_size.x / 2),
			1,
			rng.randf_range(-level_size.y / 2, level_size.y / 2)
		)
		spawn_points.append(point)

	return spawn_points

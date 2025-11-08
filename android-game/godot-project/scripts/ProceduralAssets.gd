extends Node
# Procedural asset generator for placeholder 3D models

static func create_weapon_mesh(weapon_type: String) -> Mesh:
	"""Generate procedural weapon meshes"""
	match weapon_type:
		"sword":
			return create_sword()
		"knife":
			return create_knife()
		"bow":
			return create_bow()
		"chakram":
			return create_chakram()
		_:
			return BoxMesh.new()

static func create_sword() -> Mesh:
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.1, 1.2, 0.05)
	return mesh

static func create_knife() -> Mesh:
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.05, 0.4, 0.02)
	return mesh

static func create_bow() -> Mesh:
	# Create curved bow using CSG
	var curve_mesh = CapsuleMesh.new()
	curve_mesh.height = 1.0
	curve_mesh.radius = 0.02
	return curve_mesh

static func create_chakram() -> Mesh:
	var mesh = TorusMesh.new()
	mesh.inner_radius = 0.15
	mesh.outer_radius = 0.25
	return mesh

static func create_character_mesh(character_type: String) -> Mesh:
	"""Generate procedural character meshes"""
	match character_type:
		"player":
			return create_player_capsule()
		"enemy_soldier":
			return create_soldier_capsule()
		"enemy_animal":
			return create_animal_mesh()
		"boss":
			return create_boss_mesh()
		_:
			return CapsuleMesh.new()

static func create_player_capsule() -> Mesh:
	var mesh = CapsuleMesh.new()
	mesh.height = 1.8
	mesh.radius = 0.4
	return mesh

static func create_soldier_capsule() -> Mesh:
	var mesh = CapsuleMesh.new()
	mesh.height = 1.7
	mesh.radius = 0.35
	return mesh

static func create_animal_mesh() -> Mesh:
	# Wolf/Bear shape - elongated capsule
	var mesh = CapsuleMesh.new()
	mesh.height = 1.0
	mesh.radius = 0.4
	return mesh

static func create_boss_mesh() -> Mesh:
	var mesh = CapsuleMesh.new()
	mesh.height = 3.0
	mesh.radius = 0.8
	return mesh

static func create_environment_mesh(env_type: String) -> Mesh:
	"""Generate environment meshes"""
	match env_type:
		"building":
			return create_building()
		"crate":
			return create_crate()
		"barrel":
			return create_barrel()
		"tree":
			return create_tree()
		_:
			return BoxMesh.new()

static func create_building() -> Mesh:
	var mesh = BoxMesh.new()
	mesh.size = Vector3(8.0, 6.0, 8.0)
	return mesh

static func create_crate() -> Mesh:
	var mesh = BoxMesh.new()
	mesh.size = Vector3(1.0, 1.0, 1.0)
	return mesh

static func create_barrel() -> Mesh:
	var mesh = CylinderMesh.new()
	mesh.height = 1.2
	mesh.top_radius = 0.4
	mesh.bottom_radius = 0.4
	return mesh

static func create_tree() -> Mesh:
	var mesh = CylinderMesh.new()
	mesh.height = 5.0
	mesh.top_radius = 0.3
	mesh.bottom_radius = 0.4
	return mesh

static func create_material(color: Color, metallic: float = 0.0, roughness: float = 0.5) -> StandardMaterial3D:
	"""Create procedural material"""
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material

static func create_player_material() -> StandardMaterial3D:
	return create_material(Color(0.2, 0.5, 0.8), 0.0, 0.7)

static func create_enemy_material() -> StandardMaterial3D:
	return create_material(Color(0.8, 0.2, 0.2), 0.0, 0.7)

static func create_boss_material() -> StandardMaterial3D:
	return create_material(Color(0.5, 0.1, 0.1), 0.6, 0.4)

static func create_metal_material() -> StandardMaterial3D:
	return create_material(Color(0.7, 0.7, 0.8), 0.9, 0.2)

static func create_gold_material() -> StandardMaterial3D:
	return create_material(Color(0.8, 0.6, 0.1), 0.9, 0.3)

static func create_wood_material() -> StandardMaterial3D:
	return create_material(Color(0.4, 0.25, 0.1), 0.0, 0.8)

static func create_particle_effect(effect_type: String) -> GPUParticles3D:
	"""Create particle effects"""
	var particles = GPUParticles3D.new()
	var material = ParticleProcessMaterial.new()

	match effect_type:
		"power_aura":
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			material.emission_sphere_radius = 1.0
			material.direction = Vector3(0, 1, 0)
			material.spread = 45.0
			material.gravity = Vector3(0, -2.0, 0)
			particles.amount = 50

		"boss_aura":
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			material.emission_ring_radius = 2.0
			material.emission_ring_height = 3.0
			material.direction = Vector3(0, 1, 0)
			particles.amount = 100

		"blood":
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			material.emission_sphere_radius = 0.2
			material.direction = Vector3(0, 1, 0)
			material.spread = 180.0
			material.gravity = Vector3(0, -9.8, 0)
			particles.amount = 20

		"dust":
			material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			material.emission_box_extents = Vector3(1, 0.1, 1)
			material.direction = Vector3(0, 1, 0)
			material.gravity = Vector3(0, -1.0, 0)
			particles.amount = 30

	particles.process_material = material
	particles.lifetime = 2.0
	particles.one_shot = false

	return particles

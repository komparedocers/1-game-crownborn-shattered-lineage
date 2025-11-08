extends Area3D
# Arrow projectile

var velocity: Vector3 = Vector3.ZERO
var damage: float = 15.0
var lifetime: float = 5.0

func _ready():
	body_entered.connect(_on_body_entered)

	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	position += velocity * delta

	# Point arrow in direction of travel
	if velocity.length() > 0:
		look_at(position + velocity)

func _on_body_entered(body):
	# Hit something
	if body.has_method("take_damage"):
		body.take_damage(damage)

	# Destroy arrow
	queue_free()

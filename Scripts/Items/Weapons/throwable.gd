extends Weapon
class_name Throwable

var fuse_set : bool = false

@export var throw_force : float = 20.0

func use(fuse_time: int, callback: Callable) -> void:
	# Remove item from player's inventory
	player.remove_item(self)
	
	# Set up
	free_held_scene()
	var projectile = instantiate_object_scene()
	global_transform = player.camera_controller.global_transform
	player.get_parent().add_child(self)
	
	# Determine position
	var camera = player.camera_controller
	var hand_pos = camera.global_transform.origin
	var forward = -camera.global_transform.basis.z 
	projectile.global_transform.origin = hand_pos + forward * 1.5
	
	# Apply impulse
	var impulse = camera.global_transform.basis.y + -camera.global_transform.basis.z * throw_force
	# Apply additional force if the throw is not against the direction of velocity
	var with_movement : bool = forward.dot(player.velocity) >= 0
	if player.velocity != Vector3.ZERO and with_movement:
		impulse += Vector3(player.velocity.x, 0, player.velocity.z)
	projectile.apply_impulse(impulse, forward * throw_force)
	
	# Start timer
	var timer = Timer.new()
	timer.wait_time = fuse_time
	timer.timeout.connect(callback)
	add_child(timer)
	timer.start()
	
	# Set the fuse
	fuse_set = true
	$"Grenade Object/Fuse Sound".play()

func apply_bullet_force(hit_pos: Vector3, direction: Vector3, force: float, damage: int):
	get_child(0).apply_impulse(hit_pos - global_transform.origin + direction * force)
	_apply_damage(damage)
	# HIT SOUND HERE
	# HIT PARTICLES HERE

func _apply_damage(damage: int) -> void:
	if condition - damage <= 0:
		queue_free()
	else:
		condition -= damage

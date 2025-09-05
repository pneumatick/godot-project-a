extends Weapon
class_name Throwable

var fuse_set : bool = false

@export var throw_force : float = 20.0

func use(fuse_time: float, callback: Callable) -> Timer:
	# Remove item from player's inventory
	prev_owner.remove_item(self)
	
	# Set up
	free_held_scene()
	var projectile = instantiate_object_scene()
	print(Globals.ItemManager.get_children())
	
	# Determine position
	var camera = prev_owner.camera_controller
	var hand_pos = camera.global_transform.origin
	var forward = -camera.global_transform.basis.z 
	projectile.global_transform.origin = hand_pos + forward * 1.5
	
	# Apply impulse
	var impulse = camera.global_transform.basis.y + -camera.global_transform.basis.z * throw_force
	# Apply additional force if the throw is not against the direction of velocity
	var with_movement : bool = forward.dot(prev_owner.velocity) >= 0
	if prev_owner.velocity != Vector3.ZERO and with_movement:
		impulse += Vector3(prev_owner.velocity.x, 0, prev_owner.velocity.z)
	projectile.apply_impulse(impulse, forward * throw_force)
	
	# Start timer
	var timer = Timer.new()
	timer.wait_time = fuse_time
	timer.timeout.connect(callback)
	add_child(timer)
	timer.start()
	
	# Set the fuse
	fuse_set = true
	
	return timer

## Apply incoming damage to the throwable item
func _apply_damage(hit_damage: int) -> void:
	if condition - hit_damage <= 0:
		queue_free()
	else:
		condition -= hit_damage

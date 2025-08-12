extends Throwable
class_name Grenade

@export var fuse_time: float = 3.0
@export var explosion_radius: float = 20.0
@export var explosion_damage: float = 100.0
@export var explosion_force: float = 20.0

func _init(i_owner: CharacterBody3D = null) -> void:
	prev_owner = i_owner
	
	max_ammo = 1
	current_ammo = max_ammo
	item_name = "Grenade"
	condition = 100
	value = 25
	
	# Preload scenes
	held_scene = preload("res://Scenes/Items/Weapons/grenade.tscn")
	object_scene = preload("res://Scenes/Items/Weapons/grenade_object.tscn")
	
	# Set up icon
	var image = Image.new()
	var error = image.load("res://Assets/Visuals/Icons/grenade.PNG")
	if error != OK:
		print("Error loading image: ", error)
		return
	icon = ImageTexture.create_from_image(image)

func _process(delta: float) -> void:
	if Input.is_action_pressed("fire"):
		var in_menu = player.get_in_menu()
		if _equipped and current_ammo > 0 and not in_menu:
			use(fuse_time, _on_timer_timeout)

func _on_timer_timeout():
	explode()
	print("BOOM!")

func explode():
	# Play explosion effect
	#spawn_explosion_effect(global_transform.origin)

	# Damage logic
	var explosion_area = $"Grenade Object/Explosion Area"
	var explosion_collider = explosion_area.get_child(0)
	explosion_collider.shape.radius = explosion_radius
	
	var results = explosion_area.get_overlapping_bodies()
	for result in results:
		if result == get_child(0):
			continue
		var body = result
		print("Grenade explosion hit ", body)
		
		var entity
		if body.has_method("apply_bullet_force"):
			entity = body
		elif body.get_parent().has_method("apply_bullet_force"):
			entity = body.get_parent()
		if entity:
			var hit_pos = result.position
			var direction = (hit_pos - position).normalized()
			var proportion = 1 - (explosion_area.global_position.distance_to(result.global_position) / explosion_radius)
			var damage = floori(explosion_damage * proportion)
			entity.apply_bullet_force(hit_pos, direction, explosion_force, damage)
			# Set the damager to be the new owner
			if entity.has_method("set_new_owner"):
				entity.set_new_owner(prev_owner)
		elif body.has_method("apply_damage"):
			var hit_pos = result.position
			print(explosion_area.global_position.distance_to(result.global_position))
			var proportion = 1 - (explosion_area.global_position.distance_to(result.global_position) / explosion_radius)
			print(proportion)
			var damage = floori(explosion_damage * proportion)
			body.apply_damage(damage)
	queue_free()

'''
func spawn_explosion_effect(pos: Vector3):
	var effect = preload("res://Effects/Explosion.tscn").instantiate()
	effect.global_transform.origin = pos
	get_tree().current_scene.add_child(effect)
'''

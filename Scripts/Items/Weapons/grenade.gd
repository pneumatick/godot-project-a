extends Throwable
class_name Grenade

@export var fuse_time: float = 3.0
@export var explosion_radius: float = 10.0
@export var explosion_damage: float = 100.0
@export var explosion_force: float = 20.0

var timer: Timer

func _init(i_owner: CharacterBody3D = null) -> void:
	super()
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
	var image: Texture2D = load("res://Assets/Visuals/Icons/grenade.PNG")
	icon = ImageTexture.create_from_image(image.get_image())

@rpc("any_peer", "call_local")
func pull_trigger() -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	
	var in_menu = prev_owner.get_in_menu()
	if _equipped and current_ammo > 0 and not in_menu:
		timer = use(fuse_time, _on_timer_timeout, explosion_radius)
		$"Throwable/Fuse Sound".play()

func _on_timer_timeout():
	explode()
	print("BOOM!")
	timer.queue_free()

func explode():
	# Stop fuse sound
	$"Throwable/Fuse Sound".stop()
	
	# Play explosion effect
	#spawn_explosion_effect(global_transform.origin)

	# Damage logic
	var explosion_area = $"Throwable/Explosion Area"
	var results = explosion_area.get_overlapping_bodies()
	for result in results:
		if result == $Throwable:
			continue
		var body = result
		print("Grenade explosion hit ", body)
		
		var entity
		# Former method == items, latter method == players
		if body.has_method("apply_bullet_force") or body.has_method("apply_damage"):
			entity = body
		elif body.get_parent().has_method("apply_bullet_force"):
			entity = body.get_parent()
		if entity:
			var hit_pos = result.global_position
			var direction = (hit_pos - position).normalized()
			var proportion = 1 - (explosion_area.global_position.distance_to(hit_pos) / explosion_radius)
			var hit_damage = floori(explosion_damage * proportion)
			if entity.has_method("apply_bullet_force"):
				entity.apply_bullet_force(hit_pos, direction, explosion_force, hit_damage, self)
				# Set the damager to be the new owner
				if entity.has_method("set_new_owner"):
					entity.set_new_owner(prev_owner)
			elif entity.has_method("apply_damage"):
				body.apply_damage(hit_damage, self)
	
	# Play explosion sound effect
	# NOTE: Probably a better way to do this but this works for now
	$"Throwable/Explosion Sound".play()
	visible = false
	set_physics_process(false)
	await $"Throwable/Explosion Sound".finished
	
	# NOTE: Client should not queue_free(), but the synchronizer and spawners
	# don't want to play nice and I'm tired of dealing with this shit atm so
	# this will free the item client-side and create annoying error messages for
	# now.
	queue_free()

'''
func spawn_explosion_effect(pos: Vector3):
	var effect = preload("res://Effects/Explosion.tscn").instantiate()
	effect.global_transform.origin = pos
	get_tree().current_scene.add_child(effect)
'''

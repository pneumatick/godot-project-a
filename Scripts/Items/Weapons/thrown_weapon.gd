extends RigidBody3D

var parent : Weapon

@export var resistance : int = 5

func _ready() -> void:
	parent = get_parent()

func _on_collection_area_body_entered(body: Node3D) -> void:
	if body.name == "Player" and body.is_alive():
		if parent is Throwable and parent.fuse_set:
			return
		# Remove weapon root node from world's ownership
		parent.get_parent().call_deferred("remove_child", parent)
		# Free weapon object scene
		queue_free()
		# Add weapon to the player that entered the collection area
		body.call_deferred("add_item", parent)

func apply_bullet_force(hit_pos: Vector3, direction: Vector3, force: float, damage: int):
	apply_impulse(hit_pos - global_transform.origin + direction * force)
	@warning_ignore("integer_division")
	_apply_damage(damage / resistance)
	@warning_ignore("integer_division")
	get_parent().condition -= damage / resistance
	# HIT SOUND HERE
	# HIT PARTICLES HERE

func set_new_owner(new_owner: CharacterBody3D):
	parent.prev_owner = new_owner

func _apply_damage(damage: int) -> void:
	var root_node = get_parent()
	if root_node.condition - damage <= 0:
		if root_node is Throwable:
			root_node.explode()
		else:
			root_node.queue_free()
	else:
		root_node.condition -= damage

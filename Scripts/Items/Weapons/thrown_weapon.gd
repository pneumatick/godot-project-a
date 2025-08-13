extends RigidBody3D

var parent : Weapon

@export var resistance : int = 5

func _ready() -> void:
	parent = get_parent()

func _on_collection_area_body_entered(body: Node3D) -> void:
	if body.name == "Player" and body.is_alive():
		# Remove weapon root node from world's ownership
		parent.get_parent().remove_child(parent)
		# Free weapon object scene
		queue_free()
		# Add weapon to the player that entered the collection area
		body.add_item(parent)

func apply_bullet_force(hit_pos: Vector3, direction: Vector3, force: float, damage: int):
	apply_impulse(hit_pos - global_transform.origin + direction * force)
	_apply_damage(damage / resistance)
	get_parent().condition -= damage / resistance
	# HIT SOUND HERE
	# HIT PARTICLES HERE

func set_new_owner(new_owner: CharacterBody3D):
	parent.prev_owner = new_owner

func _apply_damage(damage: int) -> void:
	if get_parent().condition - damage <= 0:
		get_parent().queue_free()
	else:
		get_parent().condition -= damage

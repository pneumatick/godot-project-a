extends RigidBody3D

var parent : Weapon
var sync: MultiplayerSynchronizer

@export var resistance : int = 5

func _ready() -> void:
	parent = get_parent()

func _on_collection_area_body_entered(body: Node3D) -> void:
	if body is Player and body.is_alive():
		if parent is Throwable and parent.fuse_set:
			return
		# Remove weapon root node from ItemManager's ownership
		#parent.get_parent().call_deferred("remove_child", parent)
		# Free weapon object scene
		#queue_free()
		
		# Add weapon to the player that entered the collection area
		body.call_deferred("add_item", parent)
		parent.prev_owner = body

func apply_bullet_force(hit_pos: Vector3, direction: Vector3, force: float, damage: int, source):
	apply_impulse(hit_pos - global_transform.origin + direction * force)
	@warning_ignore("integer_division")
	_apply_damage(damage / resistance)
	@warning_ignore("integer_division")
	set_new_owner(source.prev_owner)
	# HIT SOUND HERE
	# HIT PARTICLES HERE

func set_new_owner(new_owner: CharacterBody3D):
	parent.prev_owner = new_owner

func _apply_damage(damage: int) -> void:
	if not multiplayer.is_server():
		return
	
	if parent.condition - damage <= 0:
		if parent is Throwable:
			parent.explode()
		else:
			parent.queue_free()
	else:
		parent.condition -= damage

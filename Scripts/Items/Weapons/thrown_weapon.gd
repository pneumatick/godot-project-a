extends RigidBody3D

var parent : Weapon
var sync: MultiplayerSynchronizer

@export var resistance : int = 5

func _init() -> void:
	# Set up MultiplayerSynchronizer on Weapon root node (Node3D)
	sync = MultiplayerSynchronizer.new()
	var config  = SceneReplicationConfig.new()
	config.add_property(".:position")
	config.property_set_replication_mode(".:position", SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	config.add_property(".:rotation")
	config.property_set_replication_mode(".:rotation", SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	sync.replication_config = config
	add_child(sync)

func _ready() -> void:
	parent = get_parent()

func _on_collection_area_body_entered(body: Node3D) -> void:
	if body is Player and body.is_alive():
		if parent is Throwable and parent.fuse_set:
			return
		# Remove weapon root node from world's ownership
		parent.get_parent().call_deferred("remove_child", parent)
		# Free weapon object scene
		queue_free()
		# Add weapon to the player that entered the collection area
		body.call_deferred("add_item", parent)

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
	var root_node = get_parent()
	if root_node.condition - damage <= 0:
		if root_node is Throwable:
			print("Exploding!!!!!!!!!!!!!!")
			root_node.explode()
		else:
			root_node.queue_free()
	else:
		root_node.condition -= damage

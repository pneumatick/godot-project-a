extends Node3D
class_name Organ

var type : String = "Organ"
var prev_owner : CharacterBody3D
var num_drugs : int = 0
var item_id: int

@export var item_name : String
@export var value : int = 40
@export var condition : int = 100
@export var scene : PackedScene
@export var _timer : Timer
@export var organ_body : RigidBody3D

var sync: MultiplayerSynchronizer

func _init() -> void:
	# Set up MultiplayerSynchronizer on Organ root node (Node3D)
	sync = MultiplayerSynchronizer.new()
	var config  = SceneReplicationConfig.new()
	config.add_property("Organ:position")
	config.property_set_replication_mode("Organ:position", SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	config.add_property("Organ:rotation")
	config.property_set_replication_mode("Organ:rotation", SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	config.add_property(".:condition")
	config.property_set_replication_mode(".:condition", SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	sync.replication_config = config
	add_child(sync)
	
	add_to_group("organs")

func _enter_tree() -> void:
	sync.root_path = self.get_path()

func apply_bullet_force(hit_pos: Vector3, direction: Vector3, force: float, damage: int, source):
	var body = get_node("Organ")
	body.apply_impulse(hit_pos - global_transform.origin + direction * force)
	_apply_damage(damage)
	set_new_owner(source.prev_owner)
	# HIT SOUND HERE
	# HIT PARTICLES HERE

func set_new_owner(new_owner: CharacterBody3D):
	prev_owner = new_owner

func _on_timer_timeout() -> void:
	_apply_damage(1)
	if condition > 0:
		_timer.start()

func _apply_damage(damage: int) -> void:
	if not multiplayer.is_server():
		return
	
	if condition - damage <= 0:
		queue_free()
	else:
		condition -= damage

func interact(player: CharacterBody3D) -> void:
	if not organ_body:
		printerr("Attempt to interact with organ that has no body...")
		return
	
	organ_body.visible = false
	organ_body.set_physics_process(false)
	_timer.paused = true
	player.add_item(self)
	print(multiplayer.get_unique_id(), ": Player ", player.name, " picked up organ ", str(item_id))

func instantiate() -> Organ:
	if not has_node("Organ"):
		var child_scene = scene.instantiate()
		for node in child_scene.get_children():
			if node is Timer:
				_timer = node
				node.timeout.connect(_on_timer_timeout)
				_timer.call_deferred("start")
		child_scene.add_to_group("interactables")
		add_child(child_scene)
		organ_body = child_scene
	else:
		organ_body.visible = true
		organ_body.set_physics_process(true)
		_timer.paused = false
	
	return self

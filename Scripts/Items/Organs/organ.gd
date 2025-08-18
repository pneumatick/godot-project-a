extends Node3D
class_name Organ

var type : String = "Organ"
var prev_owner : CharacterBody3D
var num_drugs : int = 0

@export var item_name : String
@export var value : int = 40
@export var condition : int = 100
@export var scene : PackedScene
@export var _timer : Timer
#@export var organ_body : RigidBody3D

func _on_collection_area_body_entered(body: Node3D) -> void:		# Placholder: May not get equivalent (TBD)
	if body.name == "Player" and body.is_alive():
		#body.add_item(item_name)
		print("Player collected %s" % item_name)
		queue_free()

func apply_bullet_force(hit_pos: Vector3, direction: Vector3, force: float, damage: int, source):
	#organ_body.apply_impulse(hit_pos - global_transform.origin + direction * force)
	get_child(0).apply_impulse(hit_pos - global_transform.origin + direction * force)
	_apply_damage(damage)
	set_new_owner(source.prev_owner)
	# HIT SOUND HERE
	# HIT PARTICLES HERE

func set_new_owner(new_owner: CharacterBody3D):
	prev_owner = new_owner

func _on_timer_timeout() -> void:
	condition -= 1
	if condition <= 0:
		queue_free()
	else:
		_timer.start()

func _apply_damage(damage: int) -> void:
	if condition - damage <= 0:
		queue_free()
	else:
		condition -= damage

func interact(player: CharacterBody3D) -> void:
	get_child(0).free()
	get_parent().remove_child(self)
	player.add_item(self)

func instantiate() -> void:
	var child_scene = scene.instantiate()
	for node in child_scene.get_children():
		if node is Timer:
			_timer = node
			node.timeout.connect(_on_timer_timeout)
			_timer.call_deferred("start")
	child_scene.add_to_group("interactables")
	add_child(child_scene)

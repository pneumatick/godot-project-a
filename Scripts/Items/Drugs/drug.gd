extends Node3D
class_name Drug

@export var item_name : String
@export var uses : int
@export var condition : int
@export var value : int
@export var held_scene : PackedScene
@export var object_scene : PackedScene

var prev_owner : CharacterBody3D
var icon : Texture2D

var _timer : Timer

func use(_player: CharacterBody3D): pass
	
func throw(): pass

func _on_timer_timeout(): pass

func equip() -> void:
	print("Equip acknowledged from weapon")
	visible = true

func unequip() -> void:
	visible = false

func apply_bullet_force(hit_pos: Vector3, direction: Vector3, force: float, damage: int, source):
	get_child(0).apply_impulse(hit_pos - global_transform.origin + direction * force)
	_apply_damage(damage)
	set_new_owner(source.prev_owner)
	# HIT SOUND HERE
	# HIT PARTICLES HERE

func set_new_owner(new_owner: CharacterBody3D):
	prev_owner = new_owner

func _apply_damage(damage: int) -> void:
	if condition - damage <= 0:
		queue_free()
	else:
		condition -= damage

# Instantiate the scene that represents the held weapon
func instantiate_held_scene() -> void:
	var scene = held_scene.instantiate()
	for node in scene.get_children():
		if node is Timer:
			_timer = node
			_timer.timeout.connect(_on_timer_timeout)
	add_child(scene)

func instantiate_object_scene() -> Node3D:
	var scene = object_scene.instantiate()
	add_child(scene)
	return scene

# Free the scene that represents the held weapon
func free_held_scene() -> void:
	get_child(0).free()
	visible = true		# Too hacky? Made to handle drop_all_items() as expected. Consider...

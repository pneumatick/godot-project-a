extends Node3D
class_name Drug

@export var item_name : String
@export var uses : int
@export var condition : int
@export var value : int
@export var held_scene : PackedScene
@export var object_scene : PackedScene
var object_node: RigidBody3D
var held_node: Node3D
var type: String = "Drug"

var prev_owner : CharacterBody3D
var icon : Texture2D

var _equipped: bool = false

func _ready() -> void:
	object_node = get_node("DrugObject")
	object_node.add_to_group("interactables")

func _process(_delta: float) -> void:
	object_node.visible = not _equipped
	object_node.set_physics_process(not _equipped)
	object_node.get_node("CollisionShape3D").disabled = _equipped

func use(_player: CharacterBody3D): pass
	
func throw(): pass

func _on_timer_timeout(timer: Timer): pass

func apply_bullet_force(hit_pos: Vector3, direction: Vector3, force: float, damage: int, source):
	object_node.apply_impulse(hit_pos - global_transform.origin + direction * force)
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

func interact(player: CharacterBody3D) -> void:
	player.add_item(self)
	equip()

func equip() -> void:
	print("Equip acknowledged from weapon")
	if held_node:
		_equipped = true
		held_node.visible = true

func unequip() -> void:
	if held_node:
		_equipped = false
		held_node.visible = false

# Instantiate the scene that represents the held drug
func instantiate_held_scene() -> void:
	var scene = held_scene.instantiate()
	#scene.position = held_pos
	
	_equipped = true
	
	held_node = scene

func instantiate_object_scene() -> Node3D:
	free_held_scene()
	
	return object_node

# Free the scene that represents the held drug
func free_held_scene() -> void:
	if held_node:
		held_node.free()
		held_node = null
	_equipped = false

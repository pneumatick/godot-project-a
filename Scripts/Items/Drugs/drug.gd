extends Node3D
class_name Drug

@export var item_name : String
@export var uses : int
@export var condition : int
@export var value : int
@export var held_scene : PackedScene
@export var object_scene : PackedScene

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

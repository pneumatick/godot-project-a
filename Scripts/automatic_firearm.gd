extends Node3D
class_name Rifle

@export var fire_rate: float = 0.1
@export var max_ammo: int = 100
@export var max_distance: float = 1000.0
@export var damage: int = 25
@export var current_ammo = max_ammo
@export var item_name : String = "Rifle"
@export var condition : int = 100
@export var value : int = 25

@onready var player = get_node("/root/3D Scene Root/Player")
@onready var ammo_label = get_node("/root/3D Scene Root/HUD/Control/Ammo")
@onready var fire_sound : AudioStreamPlayer3D

var held_scene : PackedScene = preload("res://Scenes/rifle.tscn")
var object_scene : PackedScene = preload("res://Scenes/rifle_object.tscn")

var _can_fire : bool
var _equipped : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set default position relative to camera (center of view being origin)
	position = Vector3(0.5, -0.25, -0.25)
	_can_fire = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var in_menu = player.get_in_menu()
	if Input.is_action_pressed("fire") and _equipped and _can_fire and current_ammo > 0 and not in_menu:
		fire()
		_can_fire = false
		await get_tree().create_timer(fire_rate).timeout
		_can_fire = true

# Fire the weapon
func fire():
	if not _can_fire:
		return
	
	current_ammo -= 1
	print("Bang! Ammo: ", current_ammo)
	fire_sound.play()
	
	# Update ammo label
	ammo_label.text = "Ammo: %s" % str(current_ammo)
	
	var camera = get_viewport().get_camera_3d()
	if not camera:
		print("No camera found!")
		return
	
	var from = camera.global_transform.origin
	var to = from + camera.global_transform.basis.z * -max_distance
	
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(
			from,
			to,
			0xFFFFFFFF,			  # Default value
			[self, player]  	  # exclude gun and player
		)
	)
	
	if result:
		print("Hit: ", result.collider)
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(damage)
		if result.collider.has_method("apply_bullet_force"):
			var hit_pos = result.position
			var direction = (to - from).normalized()
			var force = 100.0
			result.collider.apply_bullet_force(hit_pos, direction, force, damage)
			result.collider.set_new_owner(player)

# Load ammo into the weapon
func load_ammo(amount: int):
	if current_ammo + amount > max_ammo:
		current_ammo = max_ammo
	else:
		current_ammo += amount

func equip() -> void:
	print("Equip acknowledged from weapon")
	_equipped = true
	visible = true
	_can_fire = true
	set_process(true)
	set_process_input(true)		# Probably not necessary

func unequip() -> void:
	_equipped = false
	visible = false
	_can_fire = false
	set_process(false)
	set_process_input(false)	# Probably not necessary

# Instantiate the scene that represents the held weapon
func instantiate_held_scene() -> void:
	var scene = held_scene.instantiate()
	for node in scene.get_children():
		if node.name == "Fire Sound":
			fire_sound = node
	_equipped = true
	add_child(scene)

func instantiate_object_scene() -> Node3D:
	var scene = object_scene.instantiate()
	add_child(scene)
	return scene

# Free the scene that represents the held weapon
func free_held_scene() -> void:
	get_child(0).queue_free()
	_equipped = false

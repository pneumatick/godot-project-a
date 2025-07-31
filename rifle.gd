extends Node3D

@export var fire_rate: float = 0.1
@export var max_ammo: int = 100
@export var max_distance: float = 1000.0
@export var damage: int = 25

@onready var player = get_node("/root/3D Scene Root/Player")

var current_ammo = max_ammo
var can_fire = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("fire") and can_fire and current_ammo > 0:
		fire()
		can_fire = false
		await get_tree().create_timer(fire_rate).timeout
		can_fire = true
		
		
func fire():
	current_ammo -= 1
	print("Bang! Ammo: ", current_ammo)
	
	var camera = get_viewport().get_camera_3d()
	if not camera:
		print("No camera found!")
		return
	
	var from = camera.global_transform.origin
	var to = from + camera.global_transform.basis.z * -max_distance  # -Z is forward
	
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(
			from,
			to,
			0xFFFFFFFF,			  # Default value
			[self, player]  # exclude gun and player
		)
	)
	
	if result:
		print("Hit: ", result.collider)
		
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(damage)

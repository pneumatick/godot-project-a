extends RigidBody3D

var type : String = "Weapon"
var prev_owner : CharacterBody3D
# These variables are manually set upon instantiation in the Player script 
# (at least for now)
var ammo : int = -1

@export var item_name : String
@export var value : int = 25

func _on_collection_area_body_entered(body: Node3D) -> void:
	if body.name == "Player" and body.is_alive():
		body.add_item(item_name, ammo)
		queue_free()

func apply_bullet_force(hit_pos: Vector3, direction: Vector3, force: float):
	apply_impulse(hit_pos - global_transform.origin + direction * force)
	# HIT SOUND HERE
	# HIT PARTICLES HERE

func set_new_owner(new_owner: CharacterBody3D):
	prev_owner = new_owner

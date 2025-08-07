extends RigidBody3D

var type : String = "Weapon"
var prev_owner : CharacterBody3D
# These variables are manually set upon instantiation in the Player script 
# (at least for now)
var ammo : int = -1

@export var item_name : String
@export var value : int = 25
@export var condition : int = 100
@export var resistance : int = 5

func _on_collection_area_body_entered(body: Node3D) -> void:
	if body.name == "Player" and body.is_alive():
		var properties = {"Name": item_name, "Ammo": ammo}
		body.add_item(properties)
		queue_free()

func apply_bullet_force(hit_pos: Vector3, direction: Vector3, force: float, damage: int):
	apply_impulse(hit_pos - global_transform.origin + direction * force)
	_apply_damage(damage / resistance)
	condition -= damage / resistance
	# HIT SOUND HERE
	# HIT PARTICLES HERE

func set_new_owner(new_owner: CharacterBody3D):
	prev_owner = new_owner

func _apply_damage(damage: int) -> void:
	if condition - damage <= 0:
		queue_free()
	else:
		condition -= damage

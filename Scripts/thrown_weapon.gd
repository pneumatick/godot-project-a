extends RigidBody3D

var type : String = "Weapon"
# These variables are manually set upon instantiation in the Player script 
# (at least for now)
var ammo : int = -1
var prev_owner : CharacterBody3D

@export var item_name : String
@export var value : int = 25

func _on_collection_area_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		body.add_item(item_name, ammo)
		queue_free()
	

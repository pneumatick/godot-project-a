extends RigidBody3D

var ammo : int = 0
var type : String = "Weapon"

var prev_owner : CharacterBody3D

@export var item_name : String
@export var value : int = 25

func _on_collection_area_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		body.add_item(item_name, ammo)
		queue_free()
	

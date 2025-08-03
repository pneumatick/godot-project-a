extends RigidBody3D

var ammo : int = 0

func _on_collection_area_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		body.add_item("Rifle", ammo)
		queue_free()

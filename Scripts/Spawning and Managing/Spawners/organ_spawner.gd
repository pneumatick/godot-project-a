extends MultiplayerSpawner

func _ready() -> void:
	spawn_function = _spawn_organs

func _spawn_organs(data: Variant) -> Node3D:
	var new_organ
	# Organ arrives as EncodedObjectAsID for client
	if data["Organ"] is EncodedObjectAsID:
		new_organ = instance_from_id(data["Organ"].object_id).new()
	else:
		new_organ = data["Organ"].new()
	
	# Initialize the organ
	new_organ.instantiate()
	new_organ.position = data["Position"]
	new_organ.num_drugs = data["Num_drugs"]
	
	return new_organ

extends MultiplayerSpawner

func _ready() -> void:
	spawn_function = _spawn_organs

func _spawn_organs(data: Variant) -> Node3D:
	var new_organ
	var pos
	if data["Organ"] is EncodedObjectAsID:
		new_organ = instance_from_id(data["Organ"].object_id).new()
		print(data["Position"])
		pos = data["Position"]
	else:
		new_organ = data["Organ"].new()
		pos = data["Position"]
	print(multiplayer.get_unique_id(), pos)
	new_organ.instantiate()
	new_organ.position = pos
	
	return new_organ

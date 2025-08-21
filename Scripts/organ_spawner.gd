extends MultiplayerSpawner

func _ready() -> void:
	spawn_function = _spawn_organs

func _spawn_organs(data: Variant) -> Node3D:
	var new_organ
	if data is EncodedObjectAsID:
		new_organ = instance_from_id(data.object_id).new()
	else:
		new_organ = data.new()
	new_organ.instantiate()
	
	return new_organ

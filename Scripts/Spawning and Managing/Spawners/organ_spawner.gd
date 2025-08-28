extends MultiplayerSpawner

var _organs: Dictionary = {}

func _ready() -> void:
	spawn_function = _spawn_organs
	
	# Prepare organ dictionary
	_organs["Heart"] = Heart
	_organs["Brain"] = Brain
	_organs["Liver"] = Liver

func _spawn_organs(data: Variant) -> Node3D:
	var organ_key: String = data["Organ"]
	var new_organ = _organs[organ_key].new()
	
	# Initialize the organ
	new_organ.instantiate()
	new_organ.position = data["Position"]
	new_organ.num_drugs = data["Num_drugs"]
	new_organ.item_id = data["ID"]
	
	return new_organ

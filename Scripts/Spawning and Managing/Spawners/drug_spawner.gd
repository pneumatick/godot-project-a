extends MultiplayerSpawner

var _drugs: Dictionary = {}

func _ready() -> void:
	spawn_function = _spawn_drug
	
	# Prepare organ dictionary
	_drugs["Crack"] = preload("uid://bfygo84ukrbh7")

func _spawn_drug(data: Variant) -> Node3D:
	var drug_key: String = data["Drug"]
	var new_drug = _drugs[drug_key].instantiate()
	
	# Initialize the organ
	new_drug.item_id = data["ID"]
	new_drug.add_to_group("drugs")
	
	return new_drug

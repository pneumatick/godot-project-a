extends MultiplayerSpawner

var _drugs: Dictionary = {}

func _ready() -> void:
	spawn_function = _spawn_drug
	
	# Prepare organ dictionary
	_drugs["Crack"] = Crack

func _spawn_drug(data: Variant) -> Node3D:
	var drug_key: String = data["Drug"]
	var new_drug = _drugs[drug_key].new()
	
	# Initialize the organ
	new_drug.instantiate()
	new_drug.item_id = data["ID"]
	
	return new_drug

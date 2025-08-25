extends MultiplayerSpawner

var _weapons: Dictionary

func _ready() -> void:
	spawn_function = _spawn_weapon
	
	_weapons = {
		"Rifle": Rifle,
		"Pistol": Pistol,
		"Grenade": Grenade
	}

func _spawn_weapon(data: Variant) -> Weapon:
	var weapon_str = data["Weapon"]
	var new_weapon = _weapons[weapon_str].new()
	
	return new_weapon

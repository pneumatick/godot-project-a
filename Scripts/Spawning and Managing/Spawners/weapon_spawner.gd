extends MultiplayerSpawner

var _weapons: Dictionary

func _ready() -> void:
	spawn_function = _spawn_weapon
	
	_weapons = {
		"Rifle": preload("uid://dsyg6wgpkw52w"),
		"Pistol": Pistol,
		"Grenade": Grenade
	}
	
	for scene in _weapons.values():
		add_spawnable_scene(scene.resource_path)
		print(scene.resource_path)

func _spawn_weapon(data: Variant) -> Weapon:
	var weapon_str = data["Weapon"]
	var new_weapon = _weapons[weapon_str].instantiate()
	new_weapon.set_multiplayer_authority(1)
	
	return new_weapon

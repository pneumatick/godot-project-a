extends Area3D

@onready var weapon_spawner: MultiplayerSpawner = $WeaponSpawner

var _available : bool = true

@export var weapon_name: String = "Rifle"			# Default: Rifle
@export var respawn_time: float = 5.0

func _ready():
	body_entered.connect(_on_body_entered)
	
	var new_node
	if weapon_name == "Rifle":
		new_node = load("res://Assets/Visuals/Models/AK-47/AK47.fbx").instantiate()
	elif weapon_name == "Pistol":
		new_node = load("res://Assets/Visuals/Models/Luger/Luger.fbx").instantiate()
	elif weapon_name == "Grenade":
		new_node = load("res://Assets/Visuals/Models/Grenade/FragGrenadeModel.fbx").instantiate()
	else:
		print("Unknown pickup item %s" % weapon_name)
		new_node.erase()
		return
	
	add_child(new_node)

func _on_body_entered(body):
	if body is Player and _available:  # Or use `is Player` if using a player class
		_available = false
		visible = false
		
		if multiplayer.is_server():
			weapon_spawner.spawn({
				"Weapon": weapon_name
			})
			rpc("_transfer_to_player", body.name)
		
		await get_tree().create_timer(respawn_time).timeout
		_available = true
		visible = true

@rpc("any_peer", "call_local")
func _transfer_to_player(id: String) -> void:
	print(multiplayer.get_unique_id(), " transfering ownership of weapon to ", id)
	for node in get_children():
		if node is Weapon:
			print(multiplayer.get_unique_id(), " found weapon to transfer ", node)
			var weapon = node
			remove_child(weapon)
			for player in %PlayerManager.get_children():
				print(multiplayer.get_unique_id(), " child of player manager: ", player)
				if player.name == id:
					print(multiplayer.get_unique_id(), " found player ", player)
					player.add_item(weapon)

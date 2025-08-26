extends Area3D

@onready var weapon_spawner: MultiplayerSpawner = %WeaponManager.get_node("WeaponSpawner")

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
			rpc("_transfer_to_player", body.name, Globals.new_item_id())
		
		await get_tree().create_timer(respawn_time).timeout
		_available = true
		visible = true

@rpc("any_peer", "call_local")
func _transfer_to_player(player_id: String, item_id: int) -> void:
	print("Looking for ", player_id)
	for node in %WeaponManager.get_children():
		if node is Weapon:
			print("Adding weapon ", node)
			var weapon = node
			print("Player list: ", get_tree().get_nodes_in_group("players"))
			for player in get_tree().get_nodes_in_group("players"):
				print("Found player ", player, " ", player.name)
				if player.name == player_id:
					# Actually transfer ownership (and initialize relevant weapon vars)
					weapon.prev_owner = player
					weapon.item_id = item_id
					var added = player.add_item(weapon)
					if added:
						print(
							multiplayer.get_unique_id(), " Added weapon ", weapon.item_id, 
							" to ", player_id
						)
					else:
						weapon.queue_free()
					return
			weapon.queue_free()

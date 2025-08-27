extends Node3D

@onready var weapon_spawner: MultiplayerSpawner = $WeaponSpawner

## Create weapon and transfer to the player
func create_and_transfer(weapon_name: String, player_id: String) -> void:
	if multiplayer.is_server():
		var weapon = weapon_spawner.spawn({
			"Weapon": weapon_name,
			"ID": Globals.new_item_id()
		})
		rpc("_transfer_to_player", player_id, weapon.item_id)

@rpc("any_peer", "call_local")
func _transfer_to_player(player_id: String, item_id: int) -> void:
	print("Looking for ", player_id)
	for weapon in get_tree().get_nodes_in_group("weapons"):
		if weapon.item_id == item_id:
			print("Adding weapon ", weapon.item_id)
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
						printerr("Add item for weapon failed (inventory full?). Freeing weapon...")
						weapon.queue_free()
					return
			# Free the weapon if the player was not found
			printerr("Player not found for weapon transfer. Freeing weapon...")
			weapon.queue_free()
			return

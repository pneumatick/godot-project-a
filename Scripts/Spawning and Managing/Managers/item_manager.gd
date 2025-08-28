extends Node3D

@onready var organ_spawner: MultiplayerSpawner = $OrganSpawner
@onready var drug_spawner: MultiplayerSpawner = $DrugSpawner

var _organs: Array = []

func _ready() -> void:
	if multiplayer.is_server():
		# Prepare organ dictionary
		_organs.append("Heart")
		_organs.append("Brain")
		_organs.append("Liver")

func spawn_organs(player: CharacterBody3D):
	if not multiplayer.is_server():
		return
	
	var camera_controller = player.camera_controller
	
	for organ in _organs:
		var new_organ = organ_spawner.spawn({
			"Organ": organ,
			"Position": player.position,
			"Num_drugs": player.get_node("Active Drugs").get_child_count(),
			"ID": Globals.new_item_id()
		})
		
		# Apply impulse
		var rand_dir = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		var impulse = camera_controller.global_transform.basis.y + -camera_controller.global_transform.basis.z * 15
		if player.velocity != Vector3.ZERO:
			impulse += player.velocity
		impulse *= rand_dir
		for node in new_organ.get_children():
			if node is RigidBody3D:
				node.apply_impulse(impulse)

func create_drug_and_transfer(drug_name: String, player_id: String) -> void:
	if not multiplayer.is_server():
		return
	
	var new_drug = drug_spawner.spawn({
		"Drug": drug_name,
		"ID": Globals.new_item_id()
	})
	
	rpc("_transfer_item_to_player", player_id, new_drug.item_id, "drugs")

@rpc("any_peer", "call_local")
func _transfer_item_to_player(player_id: String, item_id: int, group: String) -> void:
	print("Looking for ", player_id)
	for item in get_tree().get_nodes_in_group(group):
		if item.item_id == item_id:
			print("Adding item ", item.item_id)
			for player in get_tree().get_nodes_in_group("players"):
				print("Found player ", player, " ", player.name)
				if player.name == player_id:
					# Actually transfer ownership (and initialize relevant item vars)
					item.prev_owner = player
					item.item_id = item_id
					var added = player.add_item(item)
					if added:
						print(
							multiplayer.get_unique_id(), " Added item ", item.item_id, 
							" to ", player_id
						)
					else:
						printerr("Add item failed. Freeing item...")
						item.queue_free()
					return
			# Free the item if the player was not found
			printerr("Player not found for item transfer. Freeing item...")
			item.queue_free()
			return

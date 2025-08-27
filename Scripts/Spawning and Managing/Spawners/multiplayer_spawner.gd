extends MultiplayerSpawner

@export var network_player: PackedScene

func _ready() -> void:
	spawn_function = spawn_player
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	#multiplayer.connected_to_server.connect(_on_connected)

func _on_peer_connected(id):
	print(multiplayer.get_unique_id(), " Peer connected:", id)
	if multiplayer.is_server():
		spawn(id)

func _on_peer_disconnected(id):
	print(multiplayer.get_unique_id(), " Peer disconnected:", id)
	for p in get_tree().get_nodes_in_group("players"):
		if p.get_multiplayer_authority() == id:
			p.queue_free()

func _on_connected():
	print(multiplayer.get_unique_id(), " requesting spawn...")
	request_spawn.rpc()

@rpc("any_peer", "call_remote", "reliable")
func request_spawn():
	if multiplayer.is_server():
		var player_id = multiplayer.get_remote_sender_id()
		spawn_player(player_id)

func spawn_player(id: int) -> CharacterBody3D:
	print(multiplayer.get_unique_id(), " Spawning player with ID ", str(id))
	var player = network_player.instantiate()
	
	player.name = str(id)
	player.set_multiplayer_authority(id)
	player.add_to_group("players")
	
	return player

extends Node3D

@onready var spawner = $MultiplayerSpawner

const PORT = 12345

func _ready():
	# For testing: press F1 to host, F2 to join
	Input.set_custom_mouse_cursor(null) # Just to avoid UI cursor conflicts

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()
	if event.is_action_pressed("host"): # F1 or custom key → Host
		host_game()
		spawner.spawn(multiplayer.get_unique_id())
	elif event.is_action_pressed("join"): # F2 or custom key → Join
		join_game("127.0.0.1") # Join local server for now

### HOST / JOIN
func host_game():
	var peer = ENetMultiplayerPeer.new()
	var ok = peer.create_server(PORT)
	if ok != OK:
		push_error("Failed to start server")
		return
	multiplayer.multiplayer_peer = peer
	print("Hosting on port %s" % PORT)

func join_game(address: String):
	var peer = ENetMultiplayerPeer.new()
	var ok = peer.create_client(address, PORT)
	if ok != OK:
		push_error("Failed to connect")
		return
	multiplayer.multiplayer_peer = peer
	print("Joined server at %s:%s" % [address, PORT])

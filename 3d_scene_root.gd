extends Node3D

@onready var player = $Player
@onready var rifle = $"Rifle Pickup"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()

func _on_player_death() -> void:
	print("The player has died.")
	
	# Wait a bit before respawning the player
	await get_tree().create_timer(2.0).timeout
	player.respawn(Vector3(0.0, 1.0, 0.0))

func _on_gun_pickup_picked_up(weapon_name: String) -> void:
	print("%s picked up" % weapon_name)
	'''
	if weapon_name == "Rifle":
		await get_tree().create_timer(5.0).timeout
		var new_pickup = rifle.instantiate()
		new_pickup.position = Vector3(-3.0, 0.0, -3.0)
		new_pickup.connect("picked_up", Callable(self, "_on_gun_pickup_picked_up"))
		add_child(new_pickup)
	'''

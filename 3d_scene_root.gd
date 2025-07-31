extends Node3D

@onready var player = $Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()

func _on_player_death() -> void:
	print("World acknowledges that the player has died.")

func _on_gun_pickup_picked_up(weapon_name: String) -> void:
	# This also shouldn't need to exist...
	print("World acknowledges that %s was picked up" % weapon_name)

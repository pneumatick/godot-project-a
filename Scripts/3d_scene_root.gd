extends Node3D

@onready var player = $Player

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()

func _on_player_death() -> void:
	print("World acknowledges that the player has died.")

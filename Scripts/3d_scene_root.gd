extends Node3D

@onready var player = $Player

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()

func _on_player_death(source) -> void:
	print("World: Player killed by ", source)

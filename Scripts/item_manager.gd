extends Node3D

@onready var organ_spawner: MultiplayerSpawner = $OrganSpawner

var _organs : Dictionary = {}		# {String: Organ}

func _ready() -> void:
	if multiplayer.is_server():
		# Prepare organ dictionary
		_organs["Heart"] = Heart
		_organs["Brain"] = Brain
		_organs["Liver"] = Liver

func spawn_organs(player: CharacterBody3D):
	if not multiplayer.is_server():
		return
	
	var camera_controller = player.camera_controller
	
	for organ in _organs.keys():
		var new_organ = organ_spawner.spawn({
			"Organ": _organs[organ],
			"Position": player.position
		})
		new_organ.num_drugs = player.get_node("Active Drugs").get_child_count()
		
		# Apply impulse
		var rand_dir = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		var impulse = camera_controller.global_transform.basis.y + -camera_controller.global_transform.basis.z * 15
		if player.velocity != Vector3.ZERO:
			impulse += player.velocity
		impulse *= rand_dir
		for node in new_organ.get_children():
			if node is RigidBody3D:
				node.apply_impulse(impulse)

extends Organ
class_name Liver

func _init(p_owner: CharacterBody3D = null) -> void:
	prev_owner = p_owner
	
	item_name = "Liver"
	value = 45
	condition = 100
	scene = load("res://Scenes/liver.tscn")

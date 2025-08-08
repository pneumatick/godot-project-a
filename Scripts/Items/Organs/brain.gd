extends Organ
class_name Brain

func _init(p_owner: CharacterBody3D = null) -> void:
	prev_owner = p_owner
	
	item_name = "Brain"
	value = 60
	condition = 100
	scene = load("res://Scenes/Items/Organs/brain.tscn")

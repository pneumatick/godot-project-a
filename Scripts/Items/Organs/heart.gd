extends Organ
class_name Heart

func _init(p_owner: CharacterBody3D = null) -> void:
	prev_owner = p_owner
	
	item_name = "Heart"
	value = 55
	condition = 100
	scene = load("res://Scenes/Items/Organs/heart.tscn")

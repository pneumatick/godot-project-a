extends "drug.gd"
class_name Crack

@export var scene : PackedScene = preload("res://Scenes/Items/Drugs/crack.tscn")

func _init() -> void:
	item_name = "Crack"
	uses = 1
	condition = 100
	value = 55

func use():
	print("%s used" % item_name)
	
func throw():
	print("%s thrown" % item_name)

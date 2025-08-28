extends Node

var num_items: int = 0
var ItemManager: Node3D
var WeaponManager: Node3D
var PlayerList: Dictionary = {}		# Unused: Consider removing
var WeaponList: Dictionary = {}		# Unused: Consider removing

func new_item_id() -> int:
	var id = num_items
	num_items += 1
	
	return id

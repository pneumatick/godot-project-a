extends Node

var num_items: int = 0
var ItemManager: Node3D

func new_item_id() -> int:
	var id = num_items
	num_items += 1
	
	return id

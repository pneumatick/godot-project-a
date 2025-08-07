extends Area3D

signal picked_up

var _available : bool = true

@export var weapon_name: String = "Rifle"			# Default: Rifle
@export var respawn_time: float = 5.0

func _ready():
	body_entered.connect(_on_body_entered)
	
	var new_node
	if weapon_name == "Rifle":
		new_node = load("res://Assets/Visuals/Models/AK-47/AK47.fbx").instantiate()
	elif weapon_name == "Pistol":
		new_node = load("res://Assets/Visuals/Models/Luger/Luger.fbx").instantiate()
	else:
		print("Unknown pickup item %s" % weapon_name)
		new_node.erase()
		return
	
	add_child(new_node)

func _process(delta):
	pass

func _on_body_entered(body):
	if body.name == "Player" and _available:  # Or use `is Player` if using a player class
		_available = false
		visible = false
		body.add_item({"Name": weapon_name})
		await get_tree().create_timer(respawn_time).timeout
		_available = true
		visible = true

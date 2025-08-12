extends Area3D

var _available : bool = true
var _weapon

@export var weapon_name: String = "Rifle"			# Default: Rifle
@export var respawn_time: float = 5.0

func _ready():
	body_entered.connect(_on_body_entered)
	
	var new_node
	if weapon_name == "Rifle":
		new_node = load("res://Assets/Visuals/Models/AK-47/AK47.fbx").instantiate()
		_weapon = Rifle
	elif weapon_name == "Pistol":
		new_node = load("res://Assets/Visuals/Models/Luger/Luger.fbx").instantiate()
		_weapon = Pistol
	elif weapon_name == "Grenade":
		new_node = load("res://Assets/Visuals/Models/Grenade/FragGrenadeModel.fbx").instantiate()
		_weapon = Grenade
	else:
		print("Unknown pickup item %s" % weapon_name)
		new_node.erase()
		return
	
	add_child(new_node)

func _on_body_entered(body):
	if body.name == "Player" and _available:  # Or use `is Player` if using a player class
		_available = false
		visible = false
		body.add_item(_weapon.new(body))
		await get_tree().create_timer(respawn_time).timeout
		_available = true
		visible = true

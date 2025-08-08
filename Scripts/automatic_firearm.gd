extends Weapon
class_name Rifle

@export var fire_rate: float = 0.1

func _init(i_owner: CharacterBody3D = null) -> void:
	prev_owner = i_owner
	
	max_ammo = 30
	max_distance = 1000.0
	damage = 35
	current_ammo = max_ammo
	item_name = "Rifle"
	condition = 100
	value = 35
	
	held_scene = preload("res://Scenes/rifle.tscn")
	object_scene = preload("res://Scenes/rifle_object.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var in_menu = player.get_in_menu()
	if Input.is_action_pressed("fire") and _equipped and _can_fire and current_ammo > 0 and not in_menu:
		fire()
		_can_fire = false
		await get_tree().create_timer(fire_rate).timeout
		_can_fire = true

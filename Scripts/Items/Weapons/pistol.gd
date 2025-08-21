extends Weapon
class_name Pistol

func _init(i_owner: CharacterBody3D = null) -> void:
	prev_owner = i_owner
	
	max_ammo = 17
	max_distance = 1000.0
	damage = 15
	current_ammo = max_ammo
	item_name = "Pistol"
	condition = 100
	value = 25
	
	# Preload scenes
	held_scene = preload("res://Scenes/Items/Weapons/pistol.tscn")
	object_scene = preload("res://Scenes/Items/Weapons/pistol_object.tscn")
	
	# Set up icon
	var image: Texture2D = load("res://Assets/Visuals/Icons/pistol.PNG")
	icon = ImageTexture.create_from_image(image.get_image())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_pressed("fire"):
		var in_menu = prev_owner.get_in_menu()
		if _can_fire and _equipped and current_ammo > 0 and not in_menu:
			fire()
			_can_fire = false
	elif !_can_fire:
		_can_fire = true

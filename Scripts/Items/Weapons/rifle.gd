extends Weapon
class_name Rifle

@export var fire_rate: float = 0.1

func _init(i_owner: CharacterBody3D = null) -> void:
	super()
	prev_owner = i_owner
	
	max_ammo = 30
	max_distance = 1000.0
	damage = 35
	current_ammo = max_ammo
	item_name = "Rifle"
	condition = 100
	value = 35
	
	# Preload scenes
	held_scene = preload("res://Scenes/Items/Weapons/rifle.tscn")
	object_scene = preload("res://Scenes/Items/Weapons/rifle_object.tscn")
	
	# Set up icon
	var image: Texture2D = load("res://Assets/Visuals/Icons/rifle.PNG")
	icon = ImageTexture.create_from_image(image.get_image())

# Called every frame. 'delta' is the elapsed time since the previous frame.
@rpc("any_peer", "call_local")
func pull_trigger() -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	
	var in_menu = prev_owner.get_in_menu()
	if _equipped and _can_fire and current_ammo > 0 and not in_menu:
		fire()
		_can_fire = false
		await get_tree().create_timer(fire_rate).timeout
		_can_fire = true

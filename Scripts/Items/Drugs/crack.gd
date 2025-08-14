extends "drug.gd"
class_name Crack

var HEALTH_BONUS : int = 100
var DURATION : int = 20

var duration_left : int = DURATION

var _player : CharacterBody3D

@export var held : PackedScene = preload("res://Scenes/Items/Drugs/crack.tscn")
@export var object : PackedScene = preload("res://Scenes/Items/Drugs/crack.tscn")	# NOTE: Replace later

func _init() -> void:
	item_name = "Crack"
	uses = 1
	condition = 100
	value = 55
	held_scene = held
	object_scene = object
	
	# Set up icon
	var image: Texture2D = load("res://Assets/Visuals/Icons/drug.PNG")
	icon = ImageTexture.create_from_image(image.get_image())

func use(player: CharacterBody3D):
	print("%s used" % item_name)
	_player = player
	visible = false
	
	# Set initial drug effect
	player.health += HEALTH_BONUS
	
	# Start drug effect timer
	_timer.start()
	
func throw():
	print("%s thrown" % item_name)

func _on_timer_timeout():
	if duration_left <= 0:
		queue_free()
	else:
		print("Player taking crack")
		@warning_ignore("integer_division")
		_player.apply_damage(HEALTH_BONUS / DURATION, self)
		duration_left -= 1
		_timer.start()

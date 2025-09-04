extends Drug
class_name Crack

var HEALTH_BONUS : int = 100
var DURATION : int = 20

var duration_left : int = DURATION
var item_id: int

var _player : CharacterBody3D

@export var held : PackedScene = preload("res://Scenes/Items/Drugs/crack.tscn")
@export var object : PackedScene = preload("res://Scenes/Items/Drugs/crack_object.tscn")

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
	if not multiplayer.is_server():
		return
	
	print("%s used" % item_name)
	_player = player
	free_held_scene()
	
	# Set initial drug effect
	player.add_health(HEALTH_BONUS, self)
	
	# Start drug effect timer
	var timer = Timer.new()
	timer.name = str(item_id)
	timer.timeout.connect(_on_timer_timeout.bind(timer))
	player.get_node("Active Drugs").add_child(timer)
	timer.start()
	
func throw():
	print("%s thrown" % item_name)

func _on_timer_timeout(timer: Timer):
	if not multiplayer.is_server():
		return
	
	if duration_left <= 0:
			queue_free()
			timer.queue_free()
	else:
		print("Player taking crack")
		@warning_ignore("integer_division")
		_player.apply_damage(HEALTH_BONUS / DURATION, self)
		duration_left -= 1
		timer.start()

extends CharacterBody3D

# Emitted when the player is hit by a mob
signal death

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const DEFAULT_HEALTH = 100

# Variables to deal with mouse movement
var _mouse_input : bool = false
var _mouse_rotation : Vector3
var _rotation_input : float
var _tilt_input : float
var _player_rotation : Vector3
var _camera_rotation : Vector3
var _damaging_bodies : Dictionary = {}
var _items : Array = []
var _inventory : Dictionary = {}
var _alive : bool = true

@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var MOUSE_SENSITIVITY : float = 0.5
@export var health : int = DEFAULT_HEALTH

@onready var right_hand : Node3D = get_node("Pivot/Camera3D/Right Hand")

@onready var world : Node3D = get_node("/root/3D Scene Root")
@onready var health_bar : ProgressBar = get_node("/root/3D Scene Root/HUD/Control/Health Bar")
@onready var death_counter : Label = get_node("/root/3D Scene Root/HUD/Control/Death Counter")
@onready var rifle : PackedScene = preload("res://rifle.tscn")
@onready var hit_sound : AudioStreamPlayer3D = $"Hit Sound"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_bar.value = health

func _physics_process(delta: float) -> void:
	# Update the camera view
	_update_camera(delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Reset the player's position when they fall below a certain Y value
	if position.y < -10:
		position = Vector3(0.0, 0.0, 0.0)

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _input(event):
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input :
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY

func _update_camera(delta: float) -> void:
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)
	
	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	CAMERA_CONTROLLER.rotation.z = 0.0
	
	global_transform.basis = Basis.from_euler(_player_rotation)
	
	_rotation_input = 0.0
	_tilt_input = 0.0

# Handle player death logic
func die() -> void:
	_alive = false
	set_physics_process(false)
	visible = false
	velocity = Vector3.ZERO
	death_counter.text = str(int(death_counter.text) + 1)
	_inventory = {}
	_items = []
	var right_hand_children = right_hand.get_children()
	for child in right_hand_children:
		child.queue_free()
	death.emit()
	# Wait a bit before respawning the player
	await get_tree().create_timer(2.0).timeout
	respawn(Vector3(0.0, 1.0, 0.0))

func respawn(respawn_position: Vector3) -> void:
	global_transform.origin = respawn_position
	health = DEFAULT_HEALTH
	health_bar.value = health
	visible = true
	_alive = true
	set_physics_process(true)

func take_damage(amount: int) -> void:
	if health > 0:
		health -= amount
		health_bar.value = health
		print("The player was hit, health now %s" % [str(health)])
		if health <= 0 and _alive:
			die()

func _on_mob_detector_body_entered(body: Node3D) -> void:
	print("%s entered..." % [body.name])
	
	if body.has_method("get_damage_amount"):
		var damage_amount = body.get_damage_amount()
		_damaging_bodies[body] = damage_amount
		
		# Do the initial damage, and set the timer to continue doing damage
		# so long as the player remains in the body.
		if $DamageTimer.is_stopped():
			take_damage(damage_amount)
			if _alive:
				print("Starting damage timer...")
				$DamageTimer.start(0.5)

func _on_mob_detector_body_exited(body: Node3D) -> void:
	if _damaging_bodies.has(body):
		_damaging_bodies.erase(body)
		
		if _damaging_bodies.size() == 0:
			$DamageTimer.stop()

# Accumulate damage when the damage timer times out
func _on_damage_timer_timeout():
	for body in _damaging_bodies.keys():
		take_damage(_damaging_bodies[body])

# Add an item to the player's inventory (and hand)
func add_item(item_name: String):
	print("Adding %s..." % item_name)
	if item_name == "Rifle":
		var new_rifle = rifle.instantiate()
		right_hand.add_child(new_rifle)
		_inventory[item_name] = new_rifle
		_items.append(item_name)
	else:
		print("Unknown item %s" % item_name)

# Handle gun pickups
func _on_gun_pickup_picked_up(weapon_name: String) -> void:
	if _inventory.has(weapon_name):
		# This assumes that the weapon remains invisible in the hand when 
		# not in use
		var weapon = right_hand.get_node(weapon_name)
		weapon.load_ammo(weapon.max_ammo)
	else:
		add_item(weapon_name)
	print("Picked up weapon: ", weapon_name)

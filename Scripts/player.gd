extends CharacterBody3D

signal spawn
signal death
signal weapon_equipped
signal weapon_reloaded
signal weapon_picked_up
signal money_change
signal hand_empty

const SPEED = 7.5
const ACCEL = 1.0
const AIR_CONTROL = 0.3
const JUMP_VELOCITY = 4.5
const STOP_SPEED = 100
const FRICTION = 25
const DEFAULT_HEALTH = 100

var _mouse_input : bool = false
var _mouse_rotation : Vector3
var _rotation_input : float
var _tilt_input : float
var _player_rotation : Vector3
var _camera_rotation : Vector3
var _damaging_bodies : Dictionary = {}
var _items : Array = []
var _inventory : Dictionary = {}
var _equipped_item_idx : int = 0
var _weapon_scenes : Dictionary = {}
var _weapon_object_scenes : Dictionary = {}
var _alive : bool = true
var _in_menu : bool = false

@export var tilt_lower_limit := deg_to_rad(-90.0)
@export var tilt_upper_limit := deg_to_rad(90.0)
@export var camera_controller : Camera3D
@export var mouse_sensitivity : float = 0.5
@export var health : int = DEFAULT_HEALTH
@export var death_deduction : int = 15
@export var money : int = 0

# Nodes internal to scene
@onready var right_hand : Node3D = get_node("Pivot/Camera3D/Right Hand")

# Nodes external to scene
@onready var world : Node3D = get_node("/root/3D Scene Root")
@onready var health_bar : ProgressBar = get_node("/root/3D Scene Root/HUD/Control/Health Bar")
@onready var money_display : Label = get_node("/root/3D Scene Root/HUD/Control/Money")
@onready var hit_sound : AudioStreamPlayer3D = $"Hit Sound"
@onready var death_sound : AudioStreamPlayer3D = $"Death Sound"
@onready var weapon_pick_up_sound : AudioStreamPlayer3D = $"Weapon Pick Up Sound"
@onready var weapon_reload_sound : AudioStreamPlayer3D = $"Weapon Reload Sound"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_bar.value = health
	
	# Prepare weapon scenes dictionaries
	_weapon_scenes["Rifle"] = preload("res://Scenes/rifle.tscn")
	_weapon_scenes["Pistol"] = preload("res://Scenes/pistol.tscn")
	_weapon_object_scenes["Rifle"] = preload("res://Scenes/rifle_object.tscn")
	_weapon_object_scenes["Pistol"] = preload("res://Scenes/pistol_object.tscn")
	
	spawn.emit()						# Probably not supposed to be here...

func _physics_process(delta: float) -> void:
	# Update the camera view
	_update_camera(delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Reset the player's position when they fall below a certain Y value
	if position.y < -10:
		position = Vector3(0.0, 0.0, 0.0)

	# Handle movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var jumping = false
	if Input.is_action_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		
		jumping = true
		if direction:
			_air_control(direction, delta)
	elif is_on_floor():
		jumping = false
		if direction:
			if not jumping:
				velocity = direction * SPEED
				if velocity.length() > SPEED:
					velocity = velocity.normalized() * SPEED
		else:
			_apply_friction(delta)
		
	_accelerate(direction, ACCEL, SPEED, delta)
	
	print("Speed: " + str(velocity.length()))
	move_and_slide()

func _input(event):
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * mouse_sensitivity
		_tilt_input = -event.relative.y * mouse_sensitivity
	elif event.is_action_pressed("previous_item"):
		if _items.size() > 0:
			_equip_item(_equipped_item_idx - 1)
	elif event.is_action_pressed("next_item"):
		if _items.size() > 0:
			_equip_item(_equipped_item_idx + 1)
	elif event.is_action_pressed("throw_item"):
		throw_current_item()

func _accelerate(direction: Vector3, accel: float, max_speed: float, delta: float):
	var current_speed = velocity.dot(direction)
	var add_speed = max_speed - current_speed
	if add_speed <= 0:
		# Max speed reached in the given direction
		return
	
	var accel_speed = accel * delta * max_speed
	accel_speed = min(accel_speed, add_speed)
	
	velocity += direction * accel_speed

func _air_control(direction: Vector3, delta: float):
	# Prevent backward movement
	if abs(direction.dot(velocity.normalized())) < 0:
		return
	
	var speed = velocity.length()
	var dot = velocity.normalized().dot(direction)
	var k = AIR_CONTROL * dot * dot * delta
	
	if dot > 0:
		velocity += direction * k * speed

func _apply_friction(delta):
	var speed = velocity.length()
	if speed < 0.1:
		velocity = Vector3.ZERO
		return
	
	var control = max(speed, STOP_SPEED)
	var drop = FRICTION * delta
	
	var new_speed = max(speed - drop, 0)
	velocity = velocity.normalized() * new_speed

func _update_camera(delta: float) -> void:
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, tilt_lower_limit, tilt_upper_limit)
	_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)
	
	camera_controller.transform.basis = Basis.from_euler(_camera_rotation)
	camera_controller.rotation.z = 0.0
	
	global_transform.basis = Basis.from_euler(_player_rotation)
	
	_rotation_input = 0.0
	_tilt_input = 0.0

# Handle player death logic
func _die() -> void:
	_alive = false
	set_physics_process(false)
	visible = false
	velocity = Vector3.ZERO
	
	# Drop items
	drop_all_items()
	
	# Dump inventory
	_items = []
	_inventory = {}
	
	# Deduct money
	if money - death_deduction >= 0:
		remove_money(death_deduction)
	else:
		remove_money(money)
	
	# Remove whatever is in the right hand
	var right_hand_children = right_hand.get_children()
	for child in right_hand_children:
		child.queue_free()
	
	death_sound.play()
	death.emit()
	
	# Wait a bit before respawning the player
	await get_tree().create_timer(2.0).timeout
	_respawn(Vector3(0.0, 1.0, 0.0))

func _respawn(respawn_position: Vector3) -> void:
	global_transform.origin = respawn_position
	health = DEFAULT_HEALTH
	health_bar.value = health
	visible = true
	_alive = true
	set_physics_process(true)
	spawn.emit()

func _take_damage(amount: int) -> void:
	if health > 0:
		health -= amount
		health_bar.value = health
		print("The player was hit, health now %s" % [str(health)])
		if health <= 0 and _alive:
			_die()
		else:
			hit_sound.play()

func _on_mob_detector_body_entered(body: Node3D) -> void:
	print("%s entered..." % [body.name])
	
	if body.has_method("get_damage_amount"):
		var damage_amount = body.get_damage_amount()
		_damaging_bodies[body] = damage_amount
		
		# Do the initial damage, and set the timer to continue doing damage
		# so long as the player remains in the body.
		if $DamageTimer.is_stopped():
			_take_damage(damage_amount)
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
		_take_damage(_damaging_bodies[body])

# Equip held item
func _equip_item(idx: int) -> void:
	if _items.size() == 0:
		hand_empty.emit()
		return
	
	if _items.size() > 1:
		# Unequip (previously) equipped item
		_items[_equipped_item_idx].unequip()
		
	# Equip item
	idx = wrapi(idx, 0, _items.size())
	_items[idx].equip()
	weapon_equipped.emit(_items[idx])
	_equipped_item_idx = idx

# Add an item to the player's inventory (and hand, at least for now)
func add_item(item_name: String, amount: int = -1):
	print("Adding %s..." % item_name)
	# Add weapons
	if _weapon_scenes.has(item_name):
		# Add item if not already owned, otherwise replenish ammo
		if not _inventory.has(item_name):
			var new_weapon = _weapon_scenes[item_name].instantiate()
			if amount != -1:
				new_weapon.current_ammo = amount
			right_hand.add_child(new_weapon)
			_items.append(new_weapon)
			_inventory[item_name] = new_weapon
			if _items.size() == 1:
				_equip_item(0)
			else:
				new_weapon.unequip()
			weapon_picked_up.emit(new_weapon)
			weapon_pick_up_sound.play()
		else:
			# Handle weapon acquisition by reloading
			var weapon = _inventory[item_name]
			weapon.load_ammo(weapon.max_ammo)
			weapon_reload_sound.play()
			if _equipped_item_idx < _items.size() and weapon == _items[_equipped_item_idx]:
				weapon_reloaded.emit(weapon)
	else:
		print("Unknown item %s" % item_name)

#func remove_item(item_name: String) -> bool:
func remove_item(item: Node3D = null, name: String = "") -> bool:
	var removed = false
	
	var item_name : String
	if name != "":
		item_name = name
	elif item:
		item_name = item.name
	else:
		print("Error: Item removal without specifying item node or name")
		return false
	
	print("Removing %s" % item_name)
	for i in range(_items.size()):
		if _items[i] == _inventory[item_name]:
			_items.remove_at(i)
			removed = true
			# Equip the next item if possible
			#_equip_item(wrapi(i + 1, 0, _items.size()))
			break
	
	if removed:
		_inventory[item_name].queue_free()
		_inventory.erase(item_name)
		
		# Assume hand remains empty after removal
		hand_empty.emit()
	
	return removed

func _on_target_destroyed(value: int) -> void:
	add_money(value)

func add_money(amount: int) -> void:
	money += amount
	money_change.emit(money)

func remove_money(amount: int) -> bool:
	var successful = true
	
	if money - amount >= 0:
		money -= amount
		money_change.emit(money)
	else:
		successful = false
	
	return successful

func set_in_menu(state: bool) -> void:
	_in_menu = state

func get_in_menu() -> bool:
	return _in_menu

func throw_current_item():
	if _items.size() == 0:
		return

	# Create a physics copy of the items
	var current_item = _items[_equipped_item_idx]
	if _weapon_object_scenes.has(current_item.name):
		var thrown = _weapon_object_scenes[current_item.name].instantiate()
		thrown.ammo = current_item.current_ammo
		thrown.set_new_owner(self)
		get_parent().add_child(thrown)

		# Determine positiona
		var muzzle_pos = camera_controller.global_transform.origin
		var forward = -camera_controller.global_transform.basis.z 
		thrown.global_transform.origin = muzzle_pos + forward * 1.5

		# Apply impulse
		var impulse = camera_controller.global_transform.basis.y + -camera_controller.global_transform.basis.z * 5
		# Check if the throw is along the direction of movement
		var with_movement : bool = forward.dot(velocity) >= 0
		if velocity != Vector3.ZERO and with_movement:
			impulse += Vector3(velocity.x, 0, velocity.z)
		thrown.apply_impulse(impulse, forward * 15)

		# Remove the item
		remove_item(current_item)

func drop_all_items():
	for item in _items:
		if _weapon_object_scenes.has(item.name):
			var thrown = _weapon_object_scenes[item.name].instantiate()
			thrown.ammo = item.current_ammo
			thrown.set_new_owner(self)
			get_parent().add_child(thrown)

			# Determine positiona
			var muzzle_pos = camera_controller.global_transform.origin
			var forward = -camera_controller.global_transform.basis.z 
			thrown.global_transform.origin = muzzle_pos + forward * 1.5

			# Apply impulse
			var impulse = camera_controller.global_transform.basis.y + -camera_controller.global_transform.basis.z * 5
			thrown.apply_impulse(impulse, forward * 15)

	# Remove the items (Figure out a way to do this in original loop to optimize)
	for item in _items:
		remove_item(item)

func is_alive() -> bool:
	return _alive

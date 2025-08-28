extends CharacterBody3D
class_name Player

signal spawn
signal death
signal weapon_equipped
signal weapon_picked_up
signal money_change
signal hand_empty
signal viewing
signal items_changed
signal health_change

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
#var _player_rotation : Vector3
#var _camera_rotation : Vector3
var _items : Array = []
var _inventory : Dictionary = {}	# {String: Array[Items]}
var _equipped_item_idx : int = 0
var _organs : Dictionary = {}		# {String: Organ}
var _alive : bool = true
var _in_menu : bool = false

var seen_object = null
var in_shop : bool = false

@export var tilt_lower_limit := deg_to_rad(-90.0)
@export var tilt_upper_limit := deg_to_rad(90.0)
@export var camera_controller : Camera3D
@export var mouse_sensitivity : float = 0.5
@export var health : int = DEFAULT_HEALTH
@export var death_deduction : int = 15
@export var money : int = 0
@export var interaction_range : float = 3.0
@export var item_capacity : int = 6
@export var drug_limit : int = 2
var spray_texture : ImageTexture
var gravity_direction : Vector3 = Vector3.DOWN
var gravity_strength : float = 9.8

# Nodes internal to scene
@onready var right_hand : Node3D = get_node("Pivot/Camera3D/Right Hand")

# Nodes external to scene
@onready var world : Node3D = get_node("/root/3D Scene Root")
@onready var HUD: CanvasLayer = get_node("/root/3D Scene Root/HUD")
@onready var money_display : Label = get_node("/root/3D Scene Root/HUD/Control/Money")
@onready var hit_sound : AudioStreamPlayer3D = $"Hit Sound"
@onready var death_sound : AudioStreamPlayer3D = $"Death Sound"
@onready var weapon_pick_up_sound : AudioStreamPlayer3D = $"Weapon Pick Up Sound"
@onready var weapon_reload_sound : AudioStreamPlayer3D = $"Weapon Reload Sound"

func _ready() -> void:
	if is_multiplayer_authority():
		# Camera
		camera_controller.current = true
		
		# HUD
		HUD.connect_player(self)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		health_change.emit(health)
	else:
		HUD.connect_peer(self)
		camera_controller.current = false
	
	# Prepare items array
	for i in range(item_capacity):
		_items.append(null)
	
	# Prepare organ dictionary
	_organs["Heart"] = Heart
	_organs["Brain"] = Brain
	_organs["Liver"] = Liver
	
	var spray_image : Texture2D = load("res://Assets/Sprays/spray.jpg")
	spray_texture = ImageTexture.create_from_image(spray_image.get_image())
	
	spawn.emit()						# Probably not supposed to be here...

func _process(_delta: float) -> void:
	# Check for interactable objects in the player's view
	_check_interact_target()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	# Update the camera view
	_update_camera(delta)
	
	# Add the gravity.
	if not is_on_floor():
		#velocity += get_gravity() * delta
		velocity += gravity_direction * gravity_strength * delta
	
	# Reset the player's position when they fall below a certain Y value
	if position.y < -10:
		position = Vector3(0.0, 0.0, 0.0)

	# Handle movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var jumping = false
	if Input.is_action_pressed("jump"):
		if is_on_floor():
			#velocity.y = JUMP_VELOCITY
			velocity += JUMP_VELOCITY * -gravity_direction
		
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
	
	move_and_slide()

func set_gravity_direction(new_dir: Vector3):
	gravity_direction = new_dir.normalized()
	align_with_gravity_instant()

func align_with_gravity_instant():
	var up_dir = -gravity_direction
	set_up_direction(up_dir)
	'''
	var forward = transform.basis.z.normalized()
	forward = (forward - up_dir * forward.dot(up_dir)).normalized()
	var right = forward.cross(up_dir).normalized()
	transform.basis = Basis(right, up_dir, forward).orthonormalized()
	'''
	transform.basis *= Basis(
		Vector3(-1, 0, 0),
		Vector3(0, -1, 0),
		Vector3(0, 0, 1)
	)

func _input(event):
	if not is_multiplayer_authority():
		return
	
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		#_rotation_input = -event.relative.x * mouse_sensitivity
		_rotation_input = -event.relative.x * mouse_sensitivity * up_direction.y
		_tilt_input = -event.relative.y * mouse_sensitivity
	elif event.is_action_pressed("previous_item"):
			_signal_equip.rpc_id(1, wrapi(_equipped_item_idx - 1, 0, _items.size()))
	elif event.is_action_pressed("next_item"):
			_signal_equip.rpc_id(1, wrapi(_equipped_item_idx + 1, 0, _items.size()))
	elif event.is_action_pressed("throw_item"):
		_signal_throw_current_item.rpc_id(1)
	elif event.is_action_pressed("fire"):
		_fire()
	elif event.is_action_pressed("kill"):
		_suicide.rpc_id(1)
	elif event.is_action_pressed("interact"):
		_signal_interact.rpc_id(1)
	elif event.is_action_pressed("spray"):
		place_spray(spray_texture)
	elif event.is_action_pressed("invert_gravity"):
		if gravity_direction == Vector3.DOWN:
			set_gravity_direction(Vector3.UP)
		else:
			set_gravity_direction(Vector3.DOWN)

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
		
	var drop = FRICTION * delta
	
	var new_speed = max(speed - drop, 0)
	velocity = velocity.normalized() * new_speed

func _update_camera(delta: float) -> void:
	# Update pitch (X) and yaw (Y) from input
	_mouse_rotation.x = clamp(_mouse_rotation.x + _tilt_input * delta, tilt_lower_limit, tilt_upper_limit)
	_mouse_rotation.y += _rotation_input * delta
	
	'''		Old Code
	player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)
	
	camera_controller.transform.basis = Basis.from_euler(_camera_rotation)
	camera_controller.rotation.z = 0.0
	
	global_transform.basis = Basis.from_euler(_player_rotation)
	
	_rotation_input = 0.0
	_tilt_input = 0.0
	
		   New code follows...
	''' 
	
	# Apply yaw to player body in its local space
	# This keeps the camera pivot following the player
	rotate_y(_rotation_input * delta)

	# Apply pitch to camera locally (camera_controller is a child of player)
	camera_controller.rotation.x = _mouse_rotation.x
	camera_controller.rotation.z = 0.0

	# Reset input accumulators
	_rotation_input = 0.0
	_tilt_input = 0.0

@rpc("any_peer", "call_local")
func _suicide() -> void:
	if not multiplayer.is_server():
		return
	
	_die(self)

# Handle player death logic
func _die(source) -> void:
	if not multiplayer.is_server():
		return
	
	if source is Weapon:
		rpc("die_rpc", source.name, self.name, source.prev_owner.name)
	else:
		rpc("die_rpc", source.name, self.name)

@rpc("any_peer", "call_local")
func die_rpc(source: String, victim: String, killer: String = ""):
	if multiplayer.get_remote_sender_id() != 1:
		return
	
	_alive = false
	set_process(false)
	set_physics_process(false)
	visible = false
	
	# Drop items
	drop_all_items()
	
	# Clear inventory slots
	_items = []
	for i in range(item_capacity):
		_items.append(null)
	_inventory = {}
	
	# Spawn organs
	world.get_node("ItemManager").spawn_organs(self)
	
	velocity = Vector3.ZERO
	
	# Deduct money
	if money - death_deduction >= 0:
		remove_money(death_deduction)
	else:
		remove_money(money)
	
	# Remove active drugs
	var drugs = $"Active Drugs".get_children()
	for drug in drugs:
		drug.queue_free()
	
	death_sound.play()
	if killer == "":
		death.emit(source, victim)
	else:
		death.emit(source, victim, killer)
	
	# Wait a bit before respawning the player
	await get_tree().create_timer(2.0).timeout
	_respawn(Vector3(0.0, 1.0, 0.0))

func _fire() -> void:
	assert_fire.rpc_id(1)

@rpc("any_peer", "call_local", "unreliable")
func assert_fire() -> void:
	if multiplayer.is_server():
		print(multiplayer.get_unique_id(), " received fire assertion from ", multiplayer.get_remote_sender_id())
		var equipped = _items[_equipped_item_idx]
		if equipped and equipped.has_method("pull_trigger"):
			equipped.pull_trigger.rpc()

func _respawn(respawn_position: Vector3) -> void:
	global_transform.origin = respawn_position
	health = DEFAULT_HEALTH
	health_change.emit(health)
	visible = true
	_alive = true
	set_process(true)
	set_physics_process(true)
	spawn.emit()

@rpc("any_peer", "call_local")
func _take_damage(amount: int) -> void:
	health -= amount
	health_change.emit(health)
	print("The player was hit, health now %s" % [str(health)])
	hit_sound.play()

## Apply damage to the player (server-authoritative)
func apply_damage(amount: int, source) -> void:
	if multiplayer.is_server():
		_take_damage.rpc(amount)
		
		if health <= 0 and _alive:
			_die(source)

@rpc("any_peer", "call_local")
func _signal_equip(idx: int) -> void:
	if multiplayer.is_server():
		rpc("_equip_item", idx)

# Equip held item
@rpc("any_peer", "call_local")
func _equip_item(idx: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	
	# Unequip (previously) equipped item
	if _items[_equipped_item_idx]:
		_items[_equipped_item_idx].unequip()
	
	# Equip item
	if not _items[idx]:
		hand_empty.emit()
	else:
		print("Weapon equipped...")
		_items[idx].equip()
		weapon_equipped.emit(_items[idx])
	
	_equipped_item_idx = idx
	items_changed.emit(_items, _equipped_item_idx)
	print(_equipped_item_idx)

# Add an item to the player's inventory (and hand, at least for now)
func add_item(item) -> bool:
	print(multiplayer.get_unique_id(), " Adding %s..." % str(item))
	
	# Add weapons
	var added = false
	if item is Weapon:
		added = _add_weapon(item)
	# Add organs
	elif item is Organ:
		added = _add_organ(item)
		print("%s %s %s" % [str(item), item.condition, item.value])
		print(_inventory["Organs"])
	elif item is Drug:
		added = _add_drug(item)
		print(_inventory)
	else:
		print("Unknown item %s" % str(item))
	
	if added:
		print(multiplayer.get_unique_id(), " Picked up %s" % str(item))
		item.prev_owner = self
		items_changed.emit(_items, _equipped_item_idx)
	else:
		print("Failed to pick up %s" % str(item))
	
	print(_items)
	return added

func _add_weapon(weapon: Node3D) -> bool:
	# Initialize weapon
	var item_name = weapon.item_name
	
	# Check if items is at max capacity before adding to it
	var items_full = true
	for i in range(_items.size()):
		if _items[i] == null:
			weapon.instantiate_held_scene()
			items_full = false
			_items[i] = weapon
			if _items[_equipped_item_idx] == weapon:
				_equip_item(i)
			else:
				print("Unequipping %s at " % item_name, i)
				weapon.unequip()
			weapon_picked_up.emit(weapon)
			weapon_pick_up_sound.play()
			break
	
	# Get rid of instantiated weapon if item cannot be added
	if items_full:
		print("Items full!")
		#weapon.free_held_scene()
		return false
	
	# Add held item scene to hand and inventory
	right_hand.add_child(weapon.held_node)
	if not _inventory.has(item_name):
		_inventory[item_name] = [weapon]
	else:
		_inventory[item_name].append(weapon)
	
	return true

func _add_organ(organ: Organ) -> bool:
	if not _inventory.has("Organs"):
		_inventory["Organs"] = [organ]
	else:
		_inventory["Organs"].append(organ)
	
	return true

func _add_drug(drug: Drug) -> bool:
	return _add_weapon(drug)

func remove_item(item: Node3D = null) -> bool:
	print(item.get_parent())
	var removed = false
	
	var item_name : String
	if item:
		item_name = item.item_name
	else:
		print("Error: Item removal without specifying item node")
		return false
	
	print("Removing %s" % item_name)
	# Remove item from _items
	for i in range(_items.size()):
		if _items[i] == item:
			# Remove item from _inventory
			if _inventory[item_name].size() == 1:
				#right_hand.remove_child(_inventory[item_name][0].held_node)
				_inventory.erase(item_name)
			else:
				for j in range(_inventory[item_name].size()):
					if _inventory[item_name][j] == item:
						#right_hand.remove_child(_inventory[item_name][j].held_node)
						_inventory[item_name].remove_at(j)
						break
			_items[i] = null
			removed = true
			# Equip the next item if possible
			#_equip_item(wrapi(i + 1, 0, _items.size()))
			break
	
	if removed:
		# Assume hand remains empty after removal
		hand_empty.emit()
		items_changed.emit(_items, _equipped_item_idx)
		print("%s removed" % item_name)
	else:
		print("%s not removed" % item_name)
	
	return removed

func _on_target_destroyed(value: int) -> void:
	add_money(value)

## Increase the amount of money the player has
@rpc("any_peer", "call_local")
func add_money(amount: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	
	money += amount
	money_change.emit(money)

## Attempt to remove an amount of money from the player
func remove_money(amount: int) -> bool:
	var successful = true
	
	if multiplayer.is_server() and money - amount >= 0:
		rpc("broadcast_money_removal", amount)
	else:
		successful = false
	
	return successful

@rpc("any_peer", "call_local")
func broadcast_money_removal(amount: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return 
	
	money -= amount
	money_change.emit(money)

func set_in_menu(state: bool) -> void:
	_in_menu = state

func get_in_menu() -> bool:
	return _in_menu

@rpc("authority", "call_local")
func _signal_throw_current_item() -> void:
	print("Throw signal received by ", multiplayer.get_unique_id())
	if multiplayer.is_server():
		rpc("throw_current_item")

@rpc("any_peer", "call_local")
func throw_current_item():
	if _items[_equipped_item_idx] == null or multiplayer.get_remote_sender_id() != 1:
		return

	# Remove the item
	var current_item = _items[_equipped_item_idx]
	remove_item(current_item)
	
	# Create the thrown object
	var thrown = current_item.instantiate_object_scene()
	thrown.get_parent().prev_owner = self
	#get_parent().add_child(current_item)

	# Determine position
	var muzzle_pos = camera_controller.global_transform.origin
	var forward = -camera_controller.global_transform.basis.z 
	thrown.global_transform.origin = muzzle_pos + forward * 1.5

	# Apply impulse
	var impulse = camera_controller.global_transform.basis.y + -camera_controller.global_transform.basis.z * 5
	# Apply additional force if the throw is not against the direction of velocity
	var with_movement : bool = forward.dot(velocity) >= 0
	if velocity != Vector3.ZERO and with_movement:
		impulse += Vector3(velocity.x, 0, velocity.z)
	thrown.apply_impulse(impulse, forward * 15)
	
	print(_items)

func drop_all_items():
	# Drop equippable items
	for item in _items:
		if item:
			remove_item(item)	# Remove item from items/inventory
			
			# Instantiate item object
			item.instantiate_object_scene()
			item.prev_owner = self
			drop_item(item)		# Drop item into world
	
	# Drop held organs
	if _inventory.has("Organs"):
		for organ in _inventory["Organs"]:
			print("Dropping organ %s..." % organ.item_name)
			# Instantiate organ scene
			organ.instantiate()
			drop_item(organ)	# Drop organ into world
		_inventory.erase("Organs")

func drop_item(item):
	# Add item to world
	#get_parent().add_child(item)

	# Determine position
	var body: CollisionObject3D
	for node in item.get_children():
		if node is CollisionObject3D:
			body = node
	var muzzle_pos = camera_controller.global_transform.origin
	var forward = -camera_controller.global_transform.basis.z 
	body.global_transform.origin = muzzle_pos + forward * 1.5

	# Apply impulse
	var rand_dir = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	var impulse = camera_controller.global_transform.basis.y + -camera_controller.global_transform.basis.z * 15
	if velocity != Vector3.ZERO:
			impulse += velocity
	impulse *= rand_dir
	body.apply_impulse(impulse)
	

func is_alive() -> bool:
	return _alive

func _check_interact_target():
	var space_state = get_world_3d().direct_space_state
	var from = camera_controller.global_transform.origin
	var to = from + -camera_controller.global_transform.basis.z * interaction_range

	var result = space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(
			from, 
			to, 
			0xFFFFFFFF,			  # Default value
			[self]
		)
	)
	
	if result and result.collider and _alive:
		if result.collider.is_in_group("interactables") or result.collider is RigidBody3D:
			seen_object = result.collider
			viewing.emit(result.collider)
		else:
			seen_object = null
			viewing.emit()
	else:
		seen_object = null
		viewing.emit()

@rpc("any_peer", "call_local")
func _signal_interact() -> void:
	if not multiplayer.is_server():
		return
	
	if seen_object and seen_object.is_in_group("interactables"):
		#seen_object.get_parent().interact(self)
		var id: int = seen_object.get_parent().item_id
		rpc("receive_interactable", id)
	else:
		var item = _items[_equipped_item_idx]
		use_item(item)

@rpc("any_peer", "call_local")
func receive_interactable(id: int, type: String = "") -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	
	if not type.is_empty():
		if type == "Organ":
			for organ in get_tree().get_nodes_in_group("organs"):
				if organ.item_id == id:
					organ.interact(self)
					return
					
	else:
		printerr("No type specified for interaction")

func sell_all_organs() -> Array:
	if _inventory.has("Organs"):
		var organs = _inventory["Organs"]
		_inventory.erase("Organs")
		return organs
	
	return []

func use_item(item) -> void:
	if item is Drug:
		remove_item(item)				# Remove from inventory and items
		$"Active Drugs".add_child(item)
		item.use(self)
		
		# Overdose
		if $"Active Drugs".get_child_count() > drug_limit:
			_die(item)

func place_spray(image: ImageTexture):
	print("Spraying...")
	var space_state = get_world_3d().direct_space_state
	var from = camera_controller.global_position
	var to = from + camera_controller.global_transform.basis.z * -interaction_range # forward ray
	
	var result = space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(
			from, 
			to, 
			0xFFFFFFFF,			  # Default value
			[self]
		)
	)
	print(result)
	if result:
		var spray = Decal.new()
		# Make spray child of sprayed object (consider pros/cons of making it 
		# a child of the world, as most people seem to
		result.collider.get_parent().add_child(spray)
		
		# Set spray texture
		spray.texture_albedo = image
		spray.size = Vector3(1.0, 0.1, 1.0) # width, height, depth of projection box
		spray.global_position = result.position + result.normal * 0.01
		
		# Align decal to surface
		# NOTE: This blows but it's literally the only thing that would work
		if result.normal == Vector3.BACK:
			spray.rotate(Vector3.RIGHT, PI/2)
		elif result.normal == Vector3.FORWARD:
			spray.rotate(Vector3.RIGHT, PI/2)
			spray.rotate(Vector3.UP, PI)
		elif result.normal == Vector3.LEFT:
			spray.rotate(Vector3.RIGHT, PI/2)
			spray.rotate(Vector3.UP, -PI/2)
		elif result.normal == Vector3.RIGHT:
			spray.rotate(Vector3.RIGHT, PI/2)
			spray.rotate(Vector3.UP, PI/2)
		elif result.normal == Vector3.DOWN:
			spray.rotate(Vector3.RIGHT, PI)

func get_item(item_index: int) -> Node3D:
	if item_index < _items.size():
		return _items[item_index]
	return null

## Sell an item by reference
func sell_item(item: Node3D) -> bool:
	# Remove the item from the player's inventory
	var removed = remove_item(item)
	if not removed:
		return false
	
	# Add money 
	var value = floori(item.value * (float(item.condition) / 100.0))
	add_money(value)
	
	return true

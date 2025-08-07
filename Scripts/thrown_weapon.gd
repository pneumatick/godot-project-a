extends RigidBody3D

var type : String = "Weapon"
var prev_owner : CharacterBody3D
# These variables are manually set upon instantiation in the Player script 
# (at least for now)
var ammo : int = -1

@export var item_name : String
@export var value : int = 15
@export var condition : int = 100
@export var resistance : int = 5

func _ready() -> void:
	var parent = get_parent()
	item_name = parent.item_name
	value = parent.value
	condition = parent.condition

func _on_collection_area_body_entered(body: Node3D) -> void:
	if body.name == "Player" and body.is_alive():
		# Remove weapon root node from world's ownership
		get_parent().get_parent().remove_child(get_parent())
		# Free weapon object scene
		queue_free()
		# Add weapon to the player that entered the collection area
		body.add_item(get_parent())

func apply_bullet_force(hit_pos: Vector3, direction: Vector3, force: float, damage: int):
	apply_impulse(hit_pos - global_transform.origin + direction * force)
	_apply_damage(damage / resistance)
	condition -= damage / resistance
	# HIT SOUND HERE
	# HIT PARTICLES HERE

func set_new_owner(new_owner: CharacterBody3D):
	prev_owner = new_owner

func _apply_damage(damage: int) -> void:
	if condition - damage <= 0:
		get_parent().queue_free()
	else:
		condition -= damage

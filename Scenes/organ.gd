extends RigidBody3D

var type : String = "Organ"
var prev_owner : CharacterBody3D

@export var item_name : String
@export var value : int = 25
@export var condition : int = 100

func _on_collection_area_body_entered(body: Node3D) -> void:
	if body.name == "Player" and body.is_alive():
		#body.add_item(item_name)
		print("Player collected %s" % item_name)
		queue_free()

func apply_bullet_force(hit_pos: Vector3, direction: Vector3, force: float, damage: int):
	apply_impulse(hit_pos - global_transform.origin + direction * force)
	_apply_damage(damage)
	# HIT SOUND HERE
	# HIT PARTICLES HERE

func set_new_owner(new_owner: CharacterBody3D):
	prev_owner = new_owner

func _on_timer_timeout() -> void:
	condition -= 1
	if condition <= 0:
		queue_free()
	else:
		$Timer.start()

func _apply_damage(damage: int) -> void:
	if condition - damage <= 0:
		queue_free()
	else:
		condition -= damage

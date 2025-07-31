extends StaticBody3D

signal destroyed

const DEFAULT_HEALTH = 100

var health = DEFAULT_HEALTH

@onready var collision_shape = $CollisionShape3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func take_damage(amount: int) -> void:
	health -= amount
	print("Target health now %s" % health)
	if health <= 0:
		destroy()

func destroy():
	collision_shape.disabled = true 
	visible = false
	destroyed.emit()
	await get_tree().create_timer(2.0).timeout
	collision_shape.disabled = false
	visible = true
	health = DEFAULT_HEALTH

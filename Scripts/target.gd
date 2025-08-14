extends StaticBody3D

signal destroyed

const DEFAULT_HEALTH = 100

var health = DEFAULT_HEALTH

@export var value: int = 10

@onready var collision_shape = $CollisionShape3D
@onready var hit_sound = $"Hit Sound"

func apply_damage(amount: int, _source) -> void:
	health -= amount
	print("Target health now %s" % health)
	if health <= 0:
		destroy()
	else:
		hit_sound.play()

func destroy():
	collision_shape.disabled = true 
	visible = false
	# Reward the player with money
	destroyed.emit(value)
	await get_tree().create_timer(2.0).timeout
	collision_shape.disabled = false
	visible = true
	health = DEFAULT_HEALTH
	

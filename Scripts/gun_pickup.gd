extends Area3D

signal picked_up

var _available : bool = true

@export var weapon_name: String = "Rifle"			# Default: Rifle
@export var respawn_time: float = 5.0

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	pass

func _on_body_entered(body):
	if body.name == "Player" and _available:  # Or use `is Player` if using a player class
		_available = false
		visible = false
		body.add_item(weapon_name)
		await get_tree().create_timer(respawn_time).timeout
		_available = true
		visible = true

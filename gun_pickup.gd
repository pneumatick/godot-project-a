extends Area3D

signal picked_up

@export var weapon_name: String = "Rifle"			# Default: Rifle
@export var respawn_time: float = 5.0

@onready var level = get_node("/root/3D Scene Root")

var player_in_range = null

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	pass

func _on_body_entered(body):
	if body.name == "Player":  # Or use `is Player` if using a player class
		monitoring = false
		visible = false
		picked_up.emit(weapon_name)
		await get_tree().create_timer(respawn_time).timeout
		monitoring = true
		visible = true

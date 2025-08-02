extends Node

signal player_entered_shop(player)
signal player_exited_shop(player)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)
	pass

func _on_body_entered(body):
	if body.name == "Player":
		print("Player entered shop")
		emit_signal("player_entered_shop", body)

func _on_body_exited(body):
	if body.name == "Player":
		print("Player exited shop")
		emit_signal("player_exited_shop", body)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

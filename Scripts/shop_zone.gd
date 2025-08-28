extends Area3D

signal player_entered_shop(player)
signal player_exited_shop(player)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is Player:
		print("Player entered shop")
		#emit_signal("player_entered_shop", body)
		emit_signal("player_entered_shop")
		body.in_shop = true
	elif body.name == "Organ":
		pass
	elif body.get_parent() is Weapon:
		if multiplayer.is_server():
			var parent = body.get_parent()
			if parent is Throwable and parent.fuse_set:
				return
			if parent.prev_owner:
				var value
				if parent.condition > 20:
					value = floori(parent.value * (float(parent.condition) / 100.0))
				else:
					value = 5
				parent.prev_owner.rpc("add_money", value)
				parent.queue_free()

func _on_body_exited(body):
	if body is Player:
		body.in_shop = false
		print("Player exited shop")
		#emit_signal("player_exited_shop", body)
		emit_signal("player_exited_shop")
		body.set_in_menu(false)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

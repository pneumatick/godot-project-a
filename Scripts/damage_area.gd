extends StaticBody3D

@export var DAMAGE : int = 10
@export var interval : float = 0.5

func _on_body_entered(body: Node3D) -> void:
	print("%s entered..." % [str(body)])
	
	# Do the initial damage, and set the timer to continue doing damage
	# so long as the player remains in the body.
	if body.has_method("apply_damage"):
		# Create unique timer for the body
		var timer = Timer.new()
		timer.name = str(body.get_instance_id())
		timer.timeout.connect(_on_damage_timer_timeout.bind(body))
		add_child(timer)
		
		# Apply initial damage and start the timer
		body.apply_damage(DAMAGE, self)
		print("Starting damage timer...")
		timer.start(interval)

func _on_body_exited(body: Node3D) -> void:
	for node in get_children():
		print(node.name)
		if node.name == str(body.get_instance_id()):
			node.queue_free()

# Accumulate damage when the damage timer times out
func _on_damage_timer_timeout(body):
	if body.has_method("is_alive") and body.is_alive():
		body.apply_damage(DAMAGE, self)

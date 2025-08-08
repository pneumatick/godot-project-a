extends Control

@export var radius = 3.0
@export var color = Color.WHITE

func _draw() -> void:
	draw_circle(get_rect().size / 2, radius, color)

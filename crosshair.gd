extends Control

@export var radius = 3.0
@export var color = Color.WHITE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _draw() -> void:
	draw_circle(get_rect().size / 2, radius, color)

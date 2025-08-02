extends CanvasLayer

@onready var ammo_label = get_node("Control/Ammo")
@onready var money_label = get_node("Control/Money")
@onready var player = get_node("../Player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.money_change.connect(_on_player_money_change)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_player_weapon_equipped(weapon: Node) -> void:
	ammo_label.text = str(weapon.current_ammo)

func _on_player_death() -> void:
	ammo_label.text = ""

func _on_player_money_change(current_money: int) -> void:
	money_label.text = "Money: %s" % str(current_money)

func _on_player_weapon_reloaded(weapon: Node) -> void:
	ammo_label.text = str(weapon.current_ammo)

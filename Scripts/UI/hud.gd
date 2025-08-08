extends CanvasLayer

@onready var ammo_label = get_node("Control/Ammo")
@onready var money_label = get_node("Control/Money")
@onready var player = get_node("../Player")
@onready var interact_label = get_node("Control/Interact Label")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.money_change.connect(_on_player_money_change)
	player.weapon_equipped.connect(_on_player_weapon_equipped)
	player.hand_empty.connect(_on_player_hand_empty)
	player.death.connect(_on_player_death)
	player.viewing.connect(_display_interaction_label)

func _on_player_weapon_equipped(weapon: Node) -> void:
	print("HUD received weapon equipped signal")
	ammo_label.text = "Ammo: %s" % str(weapon.current_ammo)

func _on_player_death() -> void:
	ammo_label.text = ""
	$"Control/Death Counter".text = str(int($"Control/Death Counter".text) + 1)

func _on_player_money_change(current_money: int) -> void:
	money_label.text = "Money: %s" % str(current_money)

func _on_player_weapon_reloaded(weapon: Node) -> void:
	_on_player_weapon_equipped(weapon)

func _on_player_hand_empty() -> void:
	ammo_label.text = ""

func _display_interaction_label(scene = null) -> void:
	if not scene and not player.in_shop:
		interact_label.text = ""
	elif not player.get_in_menu():
		if scene:
			var parent = scene.get_parent()
			if parent is Organ:
					interact_label.text = "[Interact] %s\nCondition: %s" % [parent.item_name, str(parent.condition)]
			elif parent is Weapon:
					interact_label.text = "%s\nCondition: %s" % [parent.item_name, str(parent.condition)]
			else:
				interact_label.text = ""
		elif player.in_shop:
			interact_label.text = "[Interact] Open Shop Menu"

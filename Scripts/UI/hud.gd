extends CanvasLayer

signal slot_clicked

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
	player.items_changed.connect(_update_hotbar)
	$ShopUI.on_menu_opened.connect(_on_menu_opened)
	$ShopUI.on_menu_closed.connect(_on_menu_closed)
	$"../ShopZone".player_entered_shop.connect(_on_player_entered_shop)
	$"../ShopZone".player_exited_shop.connect(_on_player_exited_shop)
	
	# Set up item slots
	for i in range(player.item_capacity):
		var button = TextureButton.new()
		button.set_meta("item_index", i)
		button.pressed.connect(_on_hotbar_slot_pressed.bind(i))
		$"Control/Hotbar".add_child(button)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if not player.seen_object and player.in_shop:
			if !player.get_in_menu():
				$ShopUI.open_for_player()
			else:
				$ShopUI.close_for_player()

func _on_player_weapon_equipped(weapon: Node) -> void:
	print("HUD received weapon equipped signal")
	if weapon is Weapon:
		ammo_label.text = "Ammo: %s" % str(weapon.current_ammo)

func _on_player_death() -> void:
	ammo_label.text = ""
	$"Control/Death Counter".text = "Deaths: " + str(int($"Control/Death Counter".text) + 1)

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
					interact_label.text = "[Interact] %s\nCondition: %s\nDrugs Present: %s" % [parent.item_name, str(parent.condition), str(parent.num_drugs)]
			elif parent is Weapon:
					interact_label.text = "%s\nCondition: %s" % [parent.item_name, str(parent.condition)]
			else:
				interact_label.text = ""
		elif player.in_shop:
			interact_label.text = "[Interact] Open Shop Menu"
	else:
		interact_label.text = ""

func _on_menu_opened() -> void:
	$Control/Crosshair.visible = false

func _on_menu_closed() -> void:
	$Control/Crosshair.visible = true

func _on_player_entered_shop(p):
	player.in_shop = true
	$"Control/Interact Label".text = "[Interact] Open Shop Menu"

func _on_player_exited_shop(p):
	player.in_shop = false
	$ShopUI.visible = false

func _update_hotbar(items: Array, equipped_index: int):
	for i in range($Control/Hotbar.get_child_count()):
		var slot = $Control/Hotbar.get_child(i)
		if i < items.size() and items[i] != null:
			slot.texture_normal = items[i].icon
		else:
			slot.texture_normal = null
		
		# Highlight equipped slot
		if i == equipped_index:
			slot.modulate = Color(1, 1, 1) # Normal color
		else:
			slot.modulate = Color(0.5, 0.5, 0.5) # Dimmed

func _on_hotbar_slot_pressed(item_index: int) -> void:
	print("Clicked item %s" % str(item_index))
	if player.in_shop and player.get_in_menu():
		slot_clicked.emit(item_index)

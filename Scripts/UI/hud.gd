extends CanvasLayer

signal slot_clicked

@export var hotbar_icon_size : Vector2i = Vector2i(100, 100)

@onready var ammo_label = get_node("Control/Ammo")
@onready var money_label = get_node("Control/Money")
@onready var interact_label = get_node("Control/Interact Label")
@onready var health_bar = get_node("Control/Health Bar")

var player: CharacterBody3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ShopUI.on_menu_opened.connect(_on_menu_opened)
	$ShopUI.on_menu_closed.connect(_on_menu_closed)
	$"../ShopZone".player_entered_shop.connect(_on_player_entered_shop)
	$"../ShopZone".player_exited_shop.connect(_on_player_exited_shop)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if not player.seen_object and player.in_shop:
			if !player.get_in_menu():
				$ShopUI.open_for_player()
			else:
				$ShopUI.close_for_player()

func connect_player(client_player: CharacterBody3D) -> void:
	player = client_player
	player.money_change.connect(_on_player_money_change)
	player.weapon_equipped.connect(_on_player_weapon_equipped)
	player.hand_empty.connect(_on_player_hand_empty)
	player.death.connect(_on_player_death)
	player.viewing.connect(_display_interaction_label)
	player.items_changed.connect(_update_hotbar)
	player.health_change.connect(_on_health_change)
	
	# Set up item slots
	for i in range(player.item_capacity):
		var button = TextureButton.new()
		button.set_meta("item_index", i)
		button.pressed.connect(_on_hotbar_slot_pressed.bind(i))
		$"Control/Hotbar".add_child(button)
	
	# Assign player to Shop UI
	$ShopUI.player = player

func connect_peer(peer: CharacterBody3D) -> void:
	peer.death.connect(_on_player_death)

func _on_player_weapon_equipped(weapon: Node) -> void:
	print("HUD received weapon equipped signal")
	if weapon is Weapon:
		ammo_label.text = "Ammo: %s" % str(weapon.current_ammo)

func _on_player_death(source: String, victim: String, killer: String = "") -> void:
	ammo_label.text = ""
	$"Control/Death Counter".text = "Deaths: " + str(int($"Control/Death Counter".text) + 1)
	
	# Killfeed entry
	var kill_text
	if source == victim:
		kill_text = "Suicide → %s" % victim
	elif killer != "":
		kill_text = "%s → %s → %s" % [killer, source, victim]
	else:
		kill_text = "%s → %s" % [source, victim]
	
	var label = Label.new()
	label.text = kill_text
	label.add_theme_color_override("font_color", Color.WHITE)
	label.modulate.a = 0.0  # start transparent
	
	$"Control/KillFeed".add_child(label)

	# Fade in, wait, fade out, then remove
	var tween = get_tree().create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.2) # fade in
	tween.tween_interval(3.0) # stay on screen for 3 seconds
	tween.tween_property(label, "modulate:a", 0.0, 0.5) # fade out
	tween.tween_callback(label.queue_free)

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
			elif parent is Drug:
					interact_label.text = "[Interact] %s\nCondition: %s" % [parent.item_name, str(parent.condition)]
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

func _on_player_entered_shop():
	player.in_shop = true
	$"Control/Interact Label".text = "[Interact] Open Shop Menu"

func _on_player_exited_shop():
	player.in_shop = false
	$ShopUI.visible = false

func _update_hotbar(items: Array, equipped_index: int):
	for i in range($Control/Hotbar.get_child_count()):
		var slot = $Control/Hotbar.get_child(i)
		if i < items.size() and items[i] != null:
			slot.texture_normal = items[i].icon
			slot.texture_normal.set_size_override(hotbar_icon_size)
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

func _on_health_change(health: int):
	health_bar.value = health

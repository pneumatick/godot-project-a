extends Control

signal on_menu_opened()
signal on_menu_closed()

@onready var hud = get_parent()

var player: CharacterBody3D

func _ready() -> void:
	visible = false
	$"VBoxContainer/HBoxContainer/Buys/Buy Rifle".pressed.connect(_on_buy_rifle_pressed)
	$"VBoxContainer/HBoxContainer/Sells/Sell Organs".pressed.connect(_on_sell_organs_pressed)
	$"VBoxContainer/HBoxContainer/Drugs/Buy Crack".pressed.connect(_on_buy_crack_pressed)
	$"HBoxContainer/End Game".pressed.connect(_end_game)
	$Close.pressed.connect(_on_close_pressed)
	hud.slot_clicked.connect(_sell_item)

func open_for_player():
	visible = true
	player.set_in_menu(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	on_menu_opened.emit()

func close_for_player():
	_on_close_pressed()

func _on_buy_rifle_pressed():
	request_weapon_buy.rpc_id(1, "Rifle")

func _on_buy_crack_pressed():
	request_drug_buy.rpc_id(1, "Crack")

@rpc("any_peer", "call_local")
func request_weapon_buy(weapon_name: String) -> void:
	if not multiplayer.is_server():
		return
	
	var player_id: int = multiplayer.get_remote_sender_id()
	for player_node in get_tree().get_nodes_in_group("players"):
		if player_node.name == str(player_id):
			var removed = player_node.remove_money(50)
			if removed:
				Globals.WeaponManager.create_and_transfer(weapon_name, str(player_id))
				print("Player %s bought a %s!" % [str(player_id), weapon_name])
			else:
				print("Player %s does not have enough money for %s" % [str(player_id), weapon_name])

@rpc("any_peer", "call_local")
func request_drug_buy(drug_name: String) -> void:
	if not multiplayer.is_server():
		return
	
	var player_id: int = multiplayer.get_remote_sender_id()
	for player_node in get_tree().get_nodes_in_group("players"):
		if player_node.name == str(player_id):
			var has_enough = player.remove_money(15)
			if has_enough:
				Globals.ItemManager.create_drug_and_transfer(drug_name, str(player_id))
				print("Player %s bought %s!" % [str(player_id), drug_name])
			else:
				print("Player %s does not have enough money for %s" % [str(player_id), drug_name])

## Attempt to sell the selected hotbar item
func _sell_item(item_index: int):
	var item = player.get_item(item_index)
	var sold = false
	if item:
		sold = player.sell_item(item)
	else:
		print("Get item failed at index %s" % str(item_index))
	if not sold:
		print("Sell item failed for ", item, " at index ", str(item_index))

func _on_sell_organs_pressed():
	organ_sale_request.rpc_id(1)

@rpc("any_peer", "call_local")
func organ_sale_request() -> void:
	if not multiplayer.is_server():
		return
	
	var player_id: int = multiplayer.get_remote_sender_id()
	
	for player in get_tree().get_nodes_in_group("players"):
		if player.name == str(player_id):
			var organs = player.get_all_organs()
	
			if organs != []:
				var total: int = 0
				for organ in organs:
					print(organ)
					var drug_deduct = floori(organ.value * 0.20 * organ.num_drugs)
					var value = floori((organ.value - drug_deduct) * (float(organ.condition) / 100.0))
					total += value
					print(
						"%s with condition %s and %s drugs present sold for %s" % [organ.item_name, 
																str(organ.condition),
																str(organ.num_drugs), 
																str(value)]
					)
					organ.queue_free()
				# Give money to player
				player.rpc("remove_all_organs")
				player.rpc("add_money", total)

func _on_close_pressed():
	visible = false
	player.set_in_menu(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	on_menu_closed.emit()

func _end_game():
	var price = 100
	if player.money >= price:
		get_tree().quit()
	else:
		print("Player needs %s more money to end the game" % str(price - player.money))

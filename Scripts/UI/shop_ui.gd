extends Control

signal on_menu_opened()
signal on_menu_closed()

@onready var player = $"../../Player"
@onready var hud = get_parent()

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
	var has_enough = player.remove_money(50)
	if has_enough:
		player.add_item(Rifle.new(player))
		print("Player bought a rifle!")
	else:
		print("Player does not have enough money")

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
	var organs = player.sell_all_organs()
	
	if organs != []:
		for organ in organs:
			print(organ)
			var drug_deduct = floori(organ.value * 0.20 * organ.num_drugs)
			var value = floori((organ.value - drug_deduct) * (float(organ.condition) / 100.0))
			# Give money to player
			player.add_money(value)
			print(
				"%s with condition %s and %s drugs present sold for %s" % [organ.item_name, 
														str(organ.condition),
														str(organ.num_drugs), 
														str(value)]
			)

func _on_buy_crack_pressed():
	var has_enough = player.remove_money(0)
	if has_enough:
		player.add_item(Crack.new())

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

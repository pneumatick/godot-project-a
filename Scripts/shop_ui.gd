extends Control

signal on_menu_closed()

@onready var player = $"../../Player"

func _ready() -> void:
	visible = false
	$"VBoxContainer/HBoxContainer/Buys/Buy Rifle".pressed.connect(_on_buy_rifle_pressed)
	$"VBoxContainer/HBoxContainer/Sells/Sell Rifle".pressed.connect(_on_sell_rifle_pressed)
	$"VBoxContainer/HBoxContainer/Sells/Sell Organs".pressed.connect(_on_sell_organs_pressed)
	$"VBoxContainer/HBoxContainer/Drugs/Buy Crack".pressed.connect(_on_buy_crack_pressed)
	$Close.pressed.connect(_on_close_pressed)

func open_for_player():
	visible = true
	player.set_in_menu(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_for_player():
	_on_close_pressed()

func _on_buy_rifle_pressed():
	var has_enough = player.remove_money(50)
	if has_enough:
		player.add_item({"Name": "Rifle"})
		print("Player bought a rifle!")
	else:
		print("Player does not have enough money")

'''NOTE: This has broken due to the fact that multiple of the same item can be held in _items and _inventory'''
func _on_sell_rifle_pressed():
	var removed = player.remove_item(null, "Rifle")
	if removed:
		player.add_money(25)
		print("Player sold a rifle!")
	else:
		print("Rifle sale unsuccessful")

func _on_sell_organs_pressed():
	var organs = player.sell_all_organs()
	
	if organs != []:
		for organ in organs:
			print(organ)
			# Adjust price according to condition
			var organ_name : String = organ["Name"]
			var condition : int = organ["Condition"]
			var value : int = organ["Value"]
			if condition > 20:
				value = floori(value * (float(condition) / 100.0))
			else:
				value = 5
			# Give money to player
			player.add_money(value)
			print("%s with condition %s sold for %s" % [organ_name, str(condition), str(value)])

func _on_buy_crack_pressed():
	var has_enough = player.remove_money(0)
	if has_enough:
		player.add_item(Crack.new())

func _on_close_pressed():
	visible = false
	player.set_in_menu(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	on_menu_closed.emit()

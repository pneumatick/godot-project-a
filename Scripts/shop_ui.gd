extends Control

signal on_menu_closed()

@onready var player = $"../../Player"

func _ready() -> void:
	visible = false
	$"VBoxContainer/Buy Rifle".pressed.connect(_on_buy_rifle_pressed)
	$"VBoxContainer/Sell Rifle".pressed.connect(_on_sell_rifle_pressed)
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
		player.add_item("Rifle")
		print("Player bought a rifle!")
	else:
		print("Player does not have enough money")

func _on_sell_rifle_pressed():
	var removed = player.remove_item(null, "Rifle")
	if removed:
		player.add_money(25)
		print("Player sold a rifle!")
	else:
		print("Rifle sale unsuccessful")

func _on_close_pressed():
	visible = false
	player.set_in_menu(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	on_menu_closed.emit()

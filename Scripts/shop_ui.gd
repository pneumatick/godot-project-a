extends Control

signal on_menu_closed()

var _player = null

func _ready() -> void:
	visible = false
	$"VBoxContainer/Buy Rifle".pressed.connect(_on_buy_rifle_pressed)
	$"VBoxContainer/Sell Rifle".pressed.connect(_on_sell_rifle_pressed)
	$Close.pressed.connect(_on_close_pressed)

func open_for_player(player):
	visible = true
	_player = player
	_player.set_in_menu(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_buy_rifle_pressed():
	var has_enough = _player.remove_money(50)
	if has_enough:
		_player.add_item("Rifle")
		print("Player bought a rifle!")
	else:
		print("Player does not have enough money")

func _on_sell_rifle_pressed():
	var removed = _player.remove_item(null, "Rifle")
	if removed:
		_player.add_money(25)
		print("Player sold a rifle!")
	else:
		print("Rifle sale unsuccessful")

func _on_close_pressed():
	visible = false
	_player.set_in_menu(false)
	_player = null
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	on_menu_closed.emit()

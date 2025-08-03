extends Node3D

var _player_in_shop : bool = false

@onready var player = $Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ShopZone.player_entered_shop.connect(_on_player_entered_shop)
	$ShopZone.player_exited_shop.connect(_on_player_exited_shop)
	$HUD/ShopUI.on_menu_closed.connect(_on_shop_menu_closed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()
	elif event.is_action_pressed("interact") and _player_in_shop:
		$HUD/ShopUI.open_for_player(player)
		$"HUD/Control/Interact Label".visible = false

func _on_player_death() -> void:
	print("World acknowledges that the player has died.")

func _on_player_entered_shop(p):
	_player_in_shop = true
	$"HUD/Control/Interact Label".text = "[Interact] Open Shop Menu"
	$"HUD/Control/Interact Label".visible = true

func _on_player_exited_shop(p):
	_player_in_shop = false
	$HUD/ShopUI.visible = false
	$"HUD/Control/Interact Label".visible = false

func _on_shop_menu_closed():
	if _player_in_shop:
		$"HUD/Control/Interact Label".visible = true

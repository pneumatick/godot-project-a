extends Node3D

@onready var player = $Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ShopZone.player_entered_shop.connect(_on_player_entered_shop)
	$ShopZone.player_exited_shop.connect(_on_player_exited_shop)
	$HUD/ShopUI.on_menu_closed.connect(_on_shop_menu_closed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()
	elif event.is_action_pressed("interact") and player.in_shop:
		if not player.seen_object:
			if $"HUD/Control/Interact Label".visible == true:
				$HUD/ShopUI.open_for_player()
				$"HUD/Control/Interact Label".visible = false
			else:
				$HUD/ShopUI.close_for_player()
				$"HUD/Control/Interact Label".visible = true

func _on_player_death() -> void:
	print("World acknowledges that the player has died.")

func _on_player_entered_shop(p):
	player.in_shop = true
	$"HUD/Control/Interact Label".text = "[Interact] Open Shop Menu"
	$"HUD/Control/Interact Label".visible = true

func _on_player_exited_shop(p):
	player.in_shop = false
	$HUD/ShopUI.visible = false
	$"HUD/Control/Interact Label".visible = false

func _on_shop_menu_closed():
	if player.in_shop:
		$"HUD/Control/Interact Label".visible = true

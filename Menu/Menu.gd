extends Control
@onready var Map = preload("res://map_2.tscn").instantiate()


func _ready():
	show_menu()
func show_menu():
	$Quitter.show()
	$Option.show()
	$Multi.hide()
	$Jouer.show()
	$Waiting.hide()
	$Type.hide()
	$Waiting/Start.hide()
func show_type():
	$Quitter.hide()
	$Option.hide()
	$Multi.hide()
	$Jouer.hide()
	$Waiting.hide()
	$Type.show()
	$Waiting/Start.hide()
func show_multi():
	if Network_Conection.multiplayer_type == "Steam":
		$Multi/VBoxContainer/Label3.text = "lobby id:"
	elif Network_Conection.multiplayer_type == "Lan":
		$Multi/VBoxContainer/Label3.text = "host ip:"
	$Quitter.hide()
	$Option.hide()
	$Multi.show()
	$Jouer.hide()
	$Waiting.hide()
	$Type.hide()
	$Waiting/Start.hide()
func show_Waiting():
	$Quitter.hide()
	$Option.hide()
	$Multi.hide()
	$Jouer.hide()
	$Waiting.show()
	$Type.hide()
	$Waiting/Start.hide()
func _process(delta):
	pass


func StartGame(ennemy):
	get_tree().root.add_child(Map)
	Network_Conection.add_players_to_game.call_deferred(ennemy)
	UsersStartGame.rpc(ennemy)
	self.hide()
@rpc("any_peer")
func UsersStartGame(ennemy):
	get_tree().root.add_child(Map)
	Network_Conection.Player_ready.rpc(Network_Conection.self_id)
	self.hide()
func _on_quitter_pressed():
	get_tree().quit()
	


func _on_jouer_pressed():
	show_type()


func _on_join_pressed():
	if Network_Conection.multiplayer_type == "Steam":
		Network_Conection.join_lobby(decode_base35($Multi/VBoxContainer/TextEdit3.text))
	elif Network_Conection.multiplayer_type == "Lan":
		Network_Conection.join_lobby($Multi/VBoxContainer/TextEdit3.text)
	show_Waiting()
	when_lobby.call_deferred()
	
func _on_host_pressed():
	Network_Conection.create_lobby.call_deferred()
	show_Waiting()
	when_lobby.call_deferred()
	pass
func when_lobby():
	if Network_Conection.multiplayer_type == "Steam":
		$Waiting/Label.text = "waiting steam ..."
	elif Network_Conection.multiplayer_type == "Lan":
		$Waiting/Label.text = "connecting ..."
	if Network_Conection.multiplayer_type == "Steam":
		while Network_Conection.lobby_id == 0:
			await get_tree().create_timer(0.1).timeout
	if Network_Conection.multiplayer_type == "Steam":
		$Waiting/Label.text = "Steam lobby id: "+encode_base35(Network_Conection.lobby_id)+"\nwaiting for player ..."
	elif Network_Conection.multiplayer_type == "Lan":
		$Waiting/Label.text = "waiting for player ..."
	print(encode_base35(Network_Conection.lobby_id))
	while true:
		if Network_Conection.multiplayer_type == "Steam":
			if Network_Conection.is_host:
				$Waiting/Start.show()
				$Waiting/Label.text = "Steam lobby id: "+encode_base35(Network_Conection.lobby_id)+"\nPlayers: "+str(Network_Conection.lobby_members.size())
			else:
				$Waiting/Start.hide()
				$Waiting/Label.text = "Steam lobby id: "+encode_base35(Network_Conection.lobby_id)+"\nPlayers: "+str(Network_Conection.lobby_members.size())+"\nWaiting host to start .."
		elif Network_Conection.multiplayer_type == "Lan":
			if Network_Conection.is_host:
				$Waiting/Start.show()
				$Waiting/Label.text = "Players: "+str(Network_Conection.lobby_members.size())+"\nWaiting you to start .."
			else:
				$Waiting/Start.hide()
				$Waiting/Label.text = "Players: "+str(Network_Conection.lobby_members.size())+"\nWaiting host to start .."
		await get_tree().create_timer(0.1).timeout
func _on_label_gui_input(event):
	pass

# Characters used in Base35 (0–9 and A-Z, without 'O' to avoid confusion with zero)
const BASE35_CHARS := "0123456789ABCDEFGHIJKLMNPQRSTUVWXYZ"

# Encode an integer to a Base35 string
func encode_base35(number: int) -> String:
	if number == 0:
		return BASE35_CHARS[0]
	var result := ""
	var n := number
	while n > 0:
		var remainder := n % 35
		result = BASE35_CHARS[remainder] + result
		n = n / 35
	return result

# Decode a Base35 string to an integer
func decode_base35(base35_str: String) -> int:
	var result := 0
	for char in base35_str:
		var value := BASE35_CHARS.find(char)
		if value == -1:
			push_error("Invalid Base35 character: " + char)
			return -1
		result = result * 35 + value
	return result


func _on_lan_pressed() -> void:
	Network_Conection.multiplayer_type = "Lan"
	Network_Conection.init_lan()
	show_multi()


func _on_steam_pressed() -> void:
	Network_Conection.multiplayer_type = "Steam"
	Network_Conection.init_steam()
	show_multi()


func _on_start_pressed():
	if Network_Conection.is_host:
		StartGame(Network_Conection.chose_ennemy())


func _on_solo_pressed():
	Network_Conection.multiplayer_type = "Lan"
	Network_Conection.init_lan()
	Network_Conection.create_lobby()
	show_Waiting()
	StartGame(3)
	


func _on_option_pressed() -> void:
	var settings = load("res://Menu/settings.tscn").instantiate()
	get_tree().root.add_child(settings)
	self.hide()
	

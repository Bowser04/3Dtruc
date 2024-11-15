extends Control

var player_list = []
var peer:ENetMultiplayerPeer
func _ready():
	show_menu()
func show_menu():
	$Quitter.show()
	$Option.show()
	$Multi.hide()
	$Jouer.show()
	$Waiting.hide()
	$Type.hide()
func show_type():
	$Quitter.hide()
	$Option.hide()
	$Multi.hide()
	$Jouer.hide()
	$Waiting.hide()
	$Type.show()
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
func show_Waiting():
	$Quitter.hide()
	$Option.hide()
	$Multi.hide()
	$Jouer.hide()
	$Waiting.show()
	$Type.hide()
func _process(delta):
	pass
	
func StartGame():
	var scene = load("res://Map.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func _on_quitter_pressed():
	get_tree().quit()
	


func _on_jouer_pressed():
	show_type()


func _on_join_pressed():
	if Network_Conection.multiplayer_type == "Steam":
		Network_Conection.join_lobby(decode_base35($Multi/VBoxContainer/TextEdit3.text))
	show_Waiting()
	when_lobby.call_deferred(false)
	
func _on_host_pressed():
	if Network_Conection.multiplayer_type == "Steam":
		Network_Conection.create_lobby.call_deferred()
	show_Waiting()
	when_lobby.call_deferred(true)
	pass
func when_lobby(is_server):
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
		$Waiting/Label.text = "Ip: "+Network_Conection.host_ip+"\nwaiting for player ..."
	while Network_Conection.Players.size() < 1:
		await get_tree().create_timer(0.1).timeout
	while true:
		if is_server:
			$Waiting/Label.text = "Steam lobby id: "+encode_base35(Network_Conection.lobby_id)+"\nPlayers: "+str(Network_Conection.Players.size())
		else:
			$Waiting/Label.text = "Steam lobby id: "+encode_base35(Network_Conection.lobby_id)+"\nPlayers: "+str(Network_Conection.Players.size())+"\nWaiting host to start .."
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
	show_multi()


func _on_steam_pressed() -> void:
	Network_Conection.multiplayer_type = "Steam"
	show_multi()

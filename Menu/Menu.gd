extends Control

var player_list = []
var peer:ENetMultiplayerPeer
func _ready():
	$Quitter.hide()
	$Option.hide()
	$Multi.hide()
	$Jouer.show()
	$Waiting.hide()
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
# this get called on the server and clients
func peer_connected(id):
	print("Player Connected " + str(id))
	$Waiting/Label.text = "Player: "+str(0)
# this get called on the server and clients
func peer_disconnected(id):
	print("Player Disconnected " + str(id))
# called only from clients	
func connected_to_server():
	print("connected To Sever!")
# called only from clients
func connection_failed():
	print("Couldnt Connect")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
@rpc("any_peer","call_local")
func StartGame():
	var scene = load("res://Map.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func _on_quitter_pressed():
	get_tree().quit()
	


func _on_jouer_pressed():
	$Jouer.hide()
	$Multi.show()


func _on_join_pressed():
	Network_Conection.ip=$Multi/VBoxContainer/TextEdit.text
	Network_Conection.port=int($Multi/VBoxContainer/TextEdit3.text)
	print(Network_Conection.ip)
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Network_Conection.ip, Network_Conection.port)
	peer.get_host()
	multiplayer.set_multiplayer_peer(peer)
	$Quitter.hide()
	$Option.hide()
	$Jouer.hide()
	$Multi.hide()
	$Waiting.show()
	pass # Replace with function body.

func _on_host_pressed():
	Network_Conection.ip=$Multi/VBoxContainer/TextEdit.text
	Network_Conection.port=int($Multi/VBoxContainer/TextEdit3.text)
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(Network_Conection.port, 10)
	if error != OK:
		print("cannot host: " + str(error))
		return
	
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting For Players!")
	$Quitter.hide()
	$Option.hide()
	$Jouer.hide()
	$Multi.hide()
	$Waiting.show()
	pass

func _on_label_gui_input(event):
	pass

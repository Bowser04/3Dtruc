extends Control

var player_list = []
var peer:ENetMultiplayerPeer
func _ready():
	$Quitter.hide()
	$Option.hide()
	$Multi.hide()
	$Jouer.show()
	$Waiting.hide()

func _process(delta):
	pass
	
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
	Network_Conection.join_lobby(int($Multi/VBoxContainer/TextEdit3.text))

func _on_host_pressed():
	Network_Conection.create_lobby()
	pass

func _on_label_gui_input(event):
	pass

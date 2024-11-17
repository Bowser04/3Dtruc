extends Node
var ip = "127.0.0.1"
var PORT = 8910
@onready var Player_scene = preload("res://Player/Player.tscn")
var _players_spawn_node = "/root/Map2"
const PACKET_READ_LIMIT = 32
var is_host = false
var lobby_id = 0
var lobby_members = []
var lobby_member_max = 10
var steam_username= ""
var steam_id: int = 0
var self_id: int = 0
var multiplayer_type = "null"
var host_ip = "{IP}"
var ready_player = []
var peer:ENetMultiplayerPeer
var steam_peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()

#“call_local” means it will only run locally on the machine the script itself is on.
#“call_remote” is to only run it remotely on other machines.
#“any_peer” allows any connected peer to call.
#“authority” only allows the authoritative peer aka the one in control of the game state to call it.
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func init_lan():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	host_ip = str(IP.get_local_addresses()[0])
	print("Lan initialazed")
	pass
	
func peer_connected(id):
	print("Player Connected " + str(id))
	
# this get called on the server and clients
func peer_disconnected(id):
	print("Player Disconnected " + str(id))
	lobby_members.erase(id)
	var players = get_tree().get_nodes_in_group("Player")
	for i in players:
		if i.name == str(id):
			i.queue_free()
# called only from clients
func connected_to_server():
	print("connected To Sever!")
	if multiplayer_type == "Lan":
		self_id = multiplayer.get_unique_id()
		SendPlayerInformation.rpc_id(1, str(multiplayer.get_unique_id()), multiplayer.get_unique_id())
	elif multiplayer_type == "Steam":
		SendPlayerInformation.rpc_id(1, steam_username, steam_id)
@rpc("any_peer")
func SendPlayerInformation(name, id):
	var player = {"name" : name,"id" : id}
	if !lobby_members.has(player):
		lobby_members.append(player)
	
	if multiplayer.is_server():
		for i in range(len(lobby_members)):
			SendPlayerInformation.rpc(lobby_members[i].name, lobby_members[i].id)
			

# called only from clients
func connection_failed():
	print("Couldnt Connect")
func init_steam():
	OS.set_environment("SteamAppID",str(480))
	OS.set_environment("SteamGameID",str(480))
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	multiplayer.connected_to_server.connect(connected_to_server)
	initialize_steam()
	print("Steam initialazed")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	Steam.run_callbacks()
	if lobby_id > 0:
		read_all_p2p_packets()
func initialize_steam():
	var initialize_response: Dictionary = Steam.steamInitEx(true,480)
	print("Did Steam initialize?: %s " % initialize_response)
	var is_online: bool = Steam.loggedOn()
	var is_owned: bool = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	print(steam_username)
func create_lobby():
	if multiplayer_type == "Steam":
		if lobby_id == 0:
			is_host = true
			Steam.createLobby(Steam.LOBBY_TYPE_INVISIBLE,lobby_member_max)
			var error = steam_peer.create_host(0)
			if error != OK:
				print("cannot host: " + error)
				return
			multiplayer.set_multiplayer_peer(steam_peer)
	elif multiplayer_type == "Lan":
		peer = ENetMultiplayerPeer.new()
		var error = peer.create_server(PORT)
		if error != OK:
			print("cannot host: " + error)
			return
		self_id = 1
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		multiplayer.set_multiplayer_peer(peer)
		is_host = true
		print("Waiting For Players!")
func _on_lobby_created(connect: int, this_lobby_id: int):
	if connect == 1:
		lobby_id = this_lobby_id
		Steam.setLobbyJoinable(lobby_id,true)
		Steam.setLobbyData(lobby_id,"name",steam_username+"'s server")
		print("CREATED LOBBY: ",lobby_id)
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
func join_lobby(this_lobby_id):
	if multiplayer_type == "Steam":
		Steam.joinLobby(this_lobby_id)
	elif multiplayer_type == "Lan":
		peer = ENetMultiplayerPeer.new()
		peer.create_client(this_lobby_id, PORT)
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		multiplayer.set_multiplayer_peer(peer)	
func _on_lobby_joined(this_lobby_id:int, _permissions: int, _locked : bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		print("JOIN LOBBY: ",lobby_id)
		if steam_id != Steam.getLobbyOwner(lobby_id):
			var error = steam_peer.create_client(Steam.getLobbyOwner(lobby_id),0)
			if error != OK:
				print(error)
				return
			self_id = steam_id
			multiplayer.set_multiplayer_peer(steam_peer)
		
		
		
func make_p2p_handshake():
	send_p2p_packet(0,{"message":"handshake", "steam_id":steam_id,"username":steam_username})
		
func send_p2p_packet(this_target:int, packet_data: Dictionary, send_type: int = 0):
	var channel: int = 0
	var this_data: PackedByteArray
	this_data.append_array(var_to_bytes(packet_data))
	if this_target == 0:
		if lobby_members.size() > 1:
			for member in lobby_members:
				if member['steam_id'] != steam_id:
					Steam.sendP2PPacket(member['steam_id'],this_data,send_type,channel)
	else:
		Steam.sendP2PPacket(this_target,this_data,send_type,channel)

func _on_p2p_session_request(remote_id: int):
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	Steam.acceptP2PSessionWithUser(remote_id)

func read_all_p2p_packets(read_count: int = 0):
	if read_count >= PACKET_READ_LIMIT:
		return
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_packet()
		read_all_p2p_packets(read_count+1)

func read_p2p_packet():
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	if packet_size > 0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size,0)
		var packet_sender: int = this_packet['remote_steam_id']
		
		var packet_code: PackedByteArray = this_packet['data']
		var readable_data: Dictionary = bytes_to_var(packet_code)
		if readable_data.has("message"):
			match readable_data["message"]:
				"handshake":
					print("PLAYER: ",readable_data["username"], " HAS JOINED!!")
func chose_ennemy():
	var num = randi_range(-1,lobby_members.size()-1)
	var id:int
	if num == -1:
		id = self_id
	else:
		id = lobby_members[num].id
	return id
@rpc("any_peer")
func Player_ready(id):
	ready_player.append(id)
	print(id,' is ready')
@rpc("any_peer","call_local")
func add_player_to_game(player,spawn,is_ennemy):
	var parrent = get_node_or_null(_players_spawn_node)
	print("Player %s has been spawn!" % player.id)
	var player_to_add = Player_scene.instantiate()
	player_to_add.player_id = player.id
	player_to_add.is_you = self_id==player.id
	player_to_add.name = str(player.id)
	player_to_add.is_ennemy = is_ennemy
	player_to_add.global_position = spawn
	parrent.add_child(player_to_add, true)
func add_players_to_game(ennemy):
	print("ennemy is : ",ennemy)
	var parrent = get_node_or_null(_players_spawn_node)
	var spawner = get_node_or_null(_players_spawn_node+"/Spawns")
	var has_ennemy = false
	while ready_player.size() != lobby_members.size():
		await get_tree().create_timer(0.05).timeout
	if parrent:
		var spawns = spawner.get_children()
		for player in lobby_members:
			var spawn = randi_range(0,spawns.size()-1)
			add_player_to_game.rpc(player,spawns[spawn].global_position,ennemy==player.id)
			spawns.remove_at(spawn)
		print("Player %s has been spawn!" % "host")
		var spawn = randi_range(0,spawns.size()-1)
		add_player_to_game.rpc({"name" : str(self_id),"id" : self_id,},spawns[spawn].global_position,ennemy==self_id)
		spawns.remove_at(spawn)
	

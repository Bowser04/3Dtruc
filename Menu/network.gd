extends Node
var ip = "127.0.0.1"
var port = 8910
var Players = {}
const PACKET_READ_LIMIT = 32
var is_host = false
var lobby_id = 0
var lobby_members = []
var lobby_member_max = 10
var steam_username= ""
var steam_id: int = 0

#“call_local” means it will only run locally on the machine the script itself is on.
#“call_remote” is to only run it remotely on other machines.
#“any_peer” allows any connected peer to call.
#“authority” only allows the authoritative peer aka the one in control of the game state to call it.
# Called when the node enters the scene tree for the first time.
func _ready():
	OS.set_environment("SteamAppID",str(480))
	OS.set_environment("SteamGameID",str(480))
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	initialize_steam()
	pass # Replace with function body.


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
	if lobby_id == 0:
		is_host = true
		Steam.createLobby(Steam.LOBBY_TYPE_INVISIBLE,lobby_member_max)
func _on_lobby_created(connect: int, this_lobby_id: int):
	if connect == 1:
		lobby_id = this_lobby_id
		Steam.setLobbyJoinable(lobby_id,true)
		Steam.setLobbyData(lobby_id,"name",steam_username+"'s server")
		print("CREATED LOBBY: ",lobby_id)
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
func join_lobby(this_lobby_id:int):
	Steam.joinLobby(this_lobby_id)
	
func _on_lobby_joined(this_lobby_id:int, _permissions: int, _locked : bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		get_lobby_members()
		print("JOIN LOBBY: ",lobby_id)
		make_p2p_handshake()
		
		
func get_lobby_members():
	lobby_members.clear()
	var num_of_lobby_members: int = Steam.getNumLobbyMembers(lobby_id)
	
	for member in range(num_of_lobby_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id,member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		lobby_members.append({
			"steam_id":member_steam_id,
			"steam_name":member_steam_name
		})
		
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
					get_lobby_members()

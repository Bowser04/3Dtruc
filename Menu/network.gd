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

#“call_local” means it will only run locally on the machine the script itself is on.
#“call_remote” is to only run it remotely on other machines.
#“any_peer” allows any connected peer to call.
#“authority” only allows the authoritative peer aka the one in control of the game state to call it.
# Called when the node enters the scene tree for the first time.
func _ready():
	OS.set_environment("SteamAppID",str(480))
	OS.set_environment("SteamGameID",str(480))
	Steam.lobby_created.connect(_on_lobby_created)
	initialize_steam()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	Steam.run_callbacks()
func initialize_steam():
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Did Steam initialize?: %s " % initialize_response)
	var is_online: bool = Steam.loggedOn()
	var is_owned: bool = Steam.isSubscribed()
	var steam_id: int = Steam.getSteamID()
	var steam_username: String = Steam.getPersonaName()
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
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
func join_lobby(this_lobby_id:int):
	Steam.joinLobby(this_lobby_id)
	
func _on_lobby_joined(this_lobby_id:int, _permissions: int, _locked : bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		
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
		
func send_p2p_packet(this_target:int, packet_data: Dictionary, send_type: int = 0):
	var channel: int = 0

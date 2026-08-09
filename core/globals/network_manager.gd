extends Node


#region CUSTOM ENUMS

enum EJoinPeerResult {NOT_JOINING, WAITING_RESULT, FAIL, SUCCESS}

#endregion


#region CONSTANTS

## Port to use for discovery
const PORT_NETWORKING := 31983
## Port to use for the game
const PORT_GAME := 21983

## In ms.
const CONNECTION_ATTEMPT_TIMEOUT : int = 2000

#endregion


## Fired by [method NetworkManager.begin_connection_attempt] once a
## connection result occurs.[br]
## If the connection is successful, [param successful] will be true.
signal connection_result(successful: bool)


var my_ip : String
var other_ip : String

#var _roster : PeerRoster
var _join_peer_result : EJoinPeerResult = EJoinPeerResult.NOT_JOINING
var _connection_attempt_time : int


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


func _process(_delta: float) -> void:
	match _join_peer_result:
		EJoinPeerResult.WAITING_RESULT:
			if Time.get_ticks_msec() - _connection_attempt_time > CONNECTION_ATTEMPT_TIMEOUT:
				print("[NetMan]: Join peer attempt timed out. Signaling fail.")
				multiplayer.connection_failed.disconnect(_on_connection_failed)
				multiplayer.connected_to_server.disconnect(_on_connected_to_server)
				_on_join_peer_result(false)
		EJoinPeerResult.FAIL:
			print("[NetMan]: Join peer attempt failed from connection failure. Signaling fail.")
			_on_join_peer_result(false)
		EJoinPeerResult.SUCCESS:
			print("[NetMan]: Join peer attempt succeeded! Signaling success")
			_on_join_peer_result(true)


func init() -> void:
	print(Debug.HORIZONTAL_LINE_STR)
	print("[NetMan]: Initializing.")
	#_roster = PeerRoster.new()
	_load_config_ip()
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[NetMan]: Setup finished.")
	print(Debug.HORIZONTAL_LINE_STR)


## Attempts to join the server of other_ip.
## If the other device does not have a server up (i.e. no one is playing on it),
## 
func join_or_start_server() -> void:
	print("[NetMan]: join_or_start_server() called! Beginning join attempt...")
	_join_peer_result = EJoinPeerResult.WAITING_RESULT
	_connection_attempt_time = Time.get_ticks_msec()
	multiplayer.connection_failed.connect(_on_connection_failed, CONNECT_ONE_SHOT)
	multiplayer.connected_to_server.connect(_on_connected_to_server, CONNECT_ONE_SHOT)
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(other_ip, PORT_GAME)
	if error != OK:
		Debug.print_error("[State][Primary][Matchmaking]: Failed to create client. Error: %s" % error)
		return
	multiplayer.multiplayer_peer = peer


func _on_connected_to_server() -> void:
	_join_peer_result = EJoinPeerResult.SUCCESS
	multiplayer.connection_failed.disconnect(_on_connection_failed)


func _on_connection_failed() -> void:
	_join_peer_result = EJoinPeerResult.FAIL
	multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	multiplayer.multiplayer_peer.close()


func _on_join_peer_result(success: bool) -> void:
	_join_peer_result = EJoinPeerResult.NOT_JOINING
	if not success:
		print("[NetMan]: The join peer attempt failed. Starting new server.")
		#multiplayer.multiplayer_peer.close() # NOTE: Might remove. Should auto close when a game finishes anyway.
		var peer := ENetMultiplayerPeer.new()
		var error := peer.create_server(PORT_GAME, 2)
		if error != OK:
			Debug.print_error("[NetMan]: Failed to create a server. Error: %s" % error)
		else:
			Debug.print_info("[NetMan]: A new server has been created!")
			multiplayer.multiplayer_peer = peer
	connection_result.emit(success)


func _load_config_ip() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("res://cabinet.cfg") == OK:
		my_ip = cfg.get_value("network", "my_ip", "")
		other_ip = cfg.get_value("network", "other_ip", "")
	if my_ip.is_empty():
		Debug.print_error("[NetMan]: No my_ip configured in cabinet.cfg!")
		return
	if other_ip.is_empty():
		Debug.print_error("[NetMan]: No my_ip configured in cabinet.cfg!")
		return
	
	# Sanity check: confirm the configured IP is actually live on this
	# machine right now (cable plugged in, static IP applied correctly).
	var found := false
	for iface in IP.get_local_interfaces():
		if my_ip in iface["addresses"]:
			found = true
			break
	if found:
		Debug.print_success("[NetMan]: Using configured IP [b]%s[/b] (confirmed live)." % my_ip)
	else:
		Debug.print_warning("[NetMan]: Configured IP [b]%s[/b] not found on any local interface! Check the Ethernet cable / static IP setting." % my_ip)
	Debug.print_info("[NetMan]: Configured the other IP as [b]%s[/b]. Make sure you validate this on the other device." % other_ip)

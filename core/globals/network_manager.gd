extends Node
# matchmaking enter:
# broadcast STARTED
# give 2 seconds

# receive and push event

# matchmaking receive ready:
# reset timer for a decent time
# if supposed to be server:
#	create server
# 	broadcast MATCH_MADE
#	await peer connected
# else:
#	broadcast MATCH_MADE

# matchmaking receive match made:
# if supposed to be server:
# 	create server
# 	await peer connected
# else:
# 	join server
#	await connected to server


#region CUSTOM ENUMS

#enum EJoinPeerResult {NOT_JOINING, WAITING_RESULT, FAIL, SUCCESS}
#enum EStatus {INACTIVE, LOOKING, ACTIVE}

#endregion

#region CONSTANTS

## Port to use for discovery
const PORT_NETWORKING := 31983
## Port to use for the game
const PORT_GAME := 21983

## This string is appended to all packets sent over UDP.
## NetworkManager will expect packets it receives to have this header.
const UDP_HEADER = "VirtualOff"
const UDP_REQUEST_JOIN = "REQUEST_JOIN"
const UDP_OK = "OK"
const UDP_SAME_TIME = "SAME_TIME"
const UDP_NO_SERVER = "NO_SERVER"

const UDP_MATCHMAKING = "MATCHMAKING"
const UDP_REQUEST_SERVER = "REQUEST_SERVER"
const UDP_SERVER_CREATED = "SERVER_CREATED"
#const UDP_STATUS = "STATUS"
#const UDP_STATUS_REQUEST = "REQUEST"
#const UDP_STATUS_ACTIVE = "ACTIVE"
#const UDP_STATUS_LOOKING = "LOOKING"
#const UDP_STATUS_INACTIVE = "INACTIVE"
#const UDP_SERVER_REQUEST = "SERVER_REQUEST"
#const UDP_SERVER_CREATED = "SERVER_CREATED"

## In ms.
const CONNECTION_ATTEMPT_TIMEOUT : int = 3000

#endregion

#region SIGNALS

## Fired by [method NetworkManager.begin_connection_attempt] once a
## connection result occurs.[br]
## [param isMultiplayer] is true if there is an active client connected.[br]
## [param isServer] is true if we are the server.
signal connection_result(isMultiplayer: bool, isServer: bool)


signal _peer_join_req_response(response: String)

#endregion

var my_ip : String
var other_ip : String


var _is_server_up : bool = false
var _did_join_server : bool = false
# Determines if we're in the joining phase
var _is_joining : bool = false
const MAX_JOIN_ATTEMPT_TIME : float = 3
var _join_timer : float = 0


var _udp : PacketPeerUDP

var _expecting_peer := false

#var _join_peer_result : EJoinPeerResult = EJoinPeerResult.NOT_JOINING
#var _is_attempting_join := false
#var _status := EStatus.INACTIVE
#var _connection_attempt_time : int


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_connected.connect(_on_peer_connected)
	process_mode = Node.PROCESS_MODE_DISABLED


func _process(_delta: float) -> void:
	if _is_joining:
		_join_timer += _delta
		if _join_timer > MAX_JOIN_ATTEMPT_TIME:
			_peer_join_req_response.emit("")
	
	while (_udp.get_available_packet_count() > 0):
		var packetStr := _udp.get_packet().get_string_from_ascii()
		var senderIp := _udp.get_packet_ip()
		print("[NetMan]: RECEIVED: %s" % packetStr)
		if _is_udp_packet_valid(packetStr):
			_process_udp_msg(packetStr.trim_prefix(UDP_HEADER + ',').split(','))
		else:
			Debug.print_warning("[NetMan]: Received unrelated message (ip: %s | message: %s)" % [senderIp, packetStr])
	
	#if _status == EStatus.LOOKING:
		#if Time.get_ticks_msec() - _connection_attempt_time > CONNECTION_ATTEMPT_TIMEOUT:
			#print("[NetMan]: Connection search timed out. Beginning server as singleplayer.")
			#_create_server()
			#_expecting_peer = false
			#connection_result.emit(false, true)
	
	#match _join_peer_result:
		#EJoinPeerResult.WAITING_RESULT:
			#if Time.get_ticks_msec() - _connection_attempt_time > CONNECTION_ATTEMPT_TIMEOUT:
				#print("[NetMan]: Join peer attempt timed out. Signaling fail.")
				#multiplayer.connection_failed.disconnect(_on_connection_failed)
				#multiplayer.connected_to_server.disconnect(_on_connected_to_server)
				#_on_join_peer_result(false)
		#EJoinPeerResult.FAIL:
			#print("[NetMan]: Join peer attempt failed from connection failure. Signaling fail.")
			#_on_join_peer_result(false)
		#EJoinPeerResult.SUCCESS:
			#print("[NetMan]: Join peer attempt succeeded! Signaling success")
			#_on_join_peer_result(true)


func init() -> void:
	print(Debug.HORIZONTAL_LINE_STR)
	print("[NetMan]: Initializing.")
	_load_config_ip()
	_udp = PacketPeerUDP.new()
	_udp.bind(PORT_NETWORKING, my_ip)
	_udp.set_dest_address(other_ip, PORT_NETWORKING)
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[NetMan]: Setup finished.")
	print(Debug.HORIZONTAL_LINE_STR)


## Attempts to join the server of other_ip.
## If the other device does not have a server up (i.e. no one is playing on it),
## 
#func begin_matchmaking() -> void:
	#print("[NetMan]: begin_matchmaking() called! Beginning join attempt...")
	#_connection_attempt_time = Time.get_ticks_msec()
	#_broadcast(UDP_MATCHMAKING)
	#_status = EStatus.LOOKING
	#_broadcast_status(UDP_STATUS_REQUEST)
	#_join_peer_result = EJoinPeerResult.WAITING_RESULT
	#_connection_attempt_time = Time.get_ticks_msec()
	#multiplayer.connection_failed.connect(_on_connection_failed, CONNECT_ONE_SHOT)
	#multiplayer.connected_to_server.connect(_on_connected_to_server, CONNECT_ONE_SHOT)
	#var peer := ENetMultiplayerPeer.new()
	#var error := peer.create_client(other_ip, PORT_GAME)
	#if error != OK:
		#Debug.print_error("[State][Primary][Matchmaking]: Failed to create client. Error: %s" % error)
		#return
	#multiplayer.multiplayer_peer = peer


func _is_udp_packet_valid(packetStr: String) -> bool:
	return packetStr.begins_with(UDP_HEADER)


func _process_udp_msg(msgArgs: Array[String]) -> void:
	if msgArgs[0] == UDP_REQUEST_JOIN:
		if _is_joining:
			_join_timer = 0
			broadcast(UDP_SAME_TIME)
		else:
			if _is_server_up:
				broadcast(UDP_OK)
			else:
				broadcast(UDP_NO_SERVER)
	elif msgArgs[0] == UDP_REQUEST_SERVER:
		if not _is_joining:
			Debug.print_warning("[NetMan]: Received a REQUEST_SERVER while not in the _is_joining phase!")
		if _is_server_up:
			Debug.print_warning("[NetMan]: REQUEST_SERVER received but the server is already up. Broadcasting SERVER_CREATED.")
			broadcast(UDP_SERVER_CREATED)
			return
		_join_timer = 0
		create_server()
		broadcast(UDP_SERVER_CREATED)
	elif msgArgs[0] == UDP_SERVER_CREATED:
		if _did_join_server:
			Debug.print_warning("[NetMan]: SERVER_CREATED received but I've already joined the server.")
			return
		join_other_server()
	else:
		_peer_join_req_response.emit(msgArgs[0])
	
	
	#if msgArgs[0] == UDP_MATCHMAKING:
		#GameStateManager.fsm.push_event(&"other_matchmaking")
	#elif msgArgs[0] == UDP_REQUEST_SERVER:
		#GameStateManager.fsm.push_event(&"request_server")
	#elif msgArgs[0] == UDP_SERVER_CREATED:
		#GameStateManager.fsm.push_event(&"server_created")
	
	
	#if msgArgs[0] == UDP_STATUS:
		#if msgArgs[1] == UDP_STATUS_REQUEST:
			#match _status:
				#EStatus.INACTIVE:
					#_broadcast_status(UDP_STATUS_INACTIVE)
				#EStatus.LOOKING:
					## Reset connection attempt time
					#_connection_attempt_time = Time.get_ticks_msec()
					#_broadcast_status(UDP_STATUS_LOOKING)
				#EStatus.ACTIVE:
					#_broadcast_status(UDP_STATUS_ACTIVE)
		#elif _status == EStatus.ACTIVE:
			## Occurs when other devices fail to respond to a STATUS REQUEST
			## in time and we've already gone into ACTIVE (i.e. singleplayer).
			#return
		#elif msgArgs[1] == UDP_STATUS_INACTIVE:
			## Start our own server
			#_create_server()
			#_expecting_peer = false
			#connection_result.emit(false, true)
		#elif msgArgs[1] == UDP_STATUS_LOOKING:
			## Compare IPs and start a server as necessary
			## Other machine is ready to connect
			#if my_ip < other_ip:
				#_create_server()
				#_expecting_peer = true
				#_broadcast(UDP_SERVER_CREATED)
			#else:
				#_broadcast(UDP_SERVER_REQUEST)
		#elif msgArgs[1] == UDP_STATUS_ACTIVE:
			## They are a server already. Request to join
			#_join_server()
	#elif msgArgs[0] == UDP_SERVER_REQUEST:
		#if _status == EStatus.INACTIVE:
			#return
		## Other machine is ready to connect
		#_create_server()
		#_expecting_peer = true
		#_broadcast(UDP_SERVER_CREATED)
	#elif msgArgs[0] == UDP_SERVER_CREATED:
		#if _status == EStatus.INACTIVE:
			#return
		#_join_server()


func _on_connected_to_server() -> void:
	Debug.print_info("[NetMan]: Connected to the server!")
	#_status = EStatus.INACTIVE
	#_join_peer_result = EJoinPeerResult.SUCCESS
	#multiplayer.connection_failed.disconnect(_on_connection_failed)


#func _on_connection_failed() -> void:
	##_join_peer_result = EJoinPeerResult.FAIL
	#multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	#multiplayer.multiplayer_peer.close()


func _on_peer_connected(peerId: int) -> void:
	if peerId == multiplayer.get_unique_id():
		return
	Debug.print_info("[NetMan]: Peer %d connected!" % peerId)
	#_status = EStatus.INACTIVE
	#if _expecting_peer:
		#connection_result.emit(true, multiplayer.is_server())


func _create_server() -> void:
	print("[NetMan]: Creating ENet server...")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT_GAME, 2)
	if error != OK:
		Debug.print_error("[NetMan]: Failed to start server. Error: %s" % error)
		return
	multiplayer.multiplayer_peer = peer
	print("[NetMan]: Server started successfully.")
	#_status = EStatus.ACTIVE


func _join_server() -> void:
	print("[NetMan]: Creating ENet client to join existing server...")
	_expecting_peer = true
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(other_ip, PORT_GAME)
	if error != OK:
		Debug.print_error("[NetMan]: Failed to create client. Error: %s" % error)
		return
	multiplayer.multiplayer_peer = peer
	print("[NetMan]: Client created and joined successfully.")
	#state = ENetworkManagerState.CLIENT
	#state = ENetworkManagerState.IDLE # TODO: what state should be next?
	#_status = EStatus.INACTIVE


func _on_join_peer_result(success: bool) -> void:
	#_join_peer_result = EJoinPeerResult.NOT_JOINING
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


func broadcast(...args: Array) -> void:
	var packet : String = UDP_HEADER
	for arg in args:
		packet += ',' + str(arg)
	print("[NetMan]: BROADCASTING: %s" % packet)
	_udp.put_packet(packet.to_utf8_buffer())


func join_or_begin_session() -> void:
	Debug.print_info("[NetMan]: join_or_begin_session() called.")
	_is_joining = true
	broadcast(UDP_REQUEST_JOIN)
	var response : String = await _peer_join_req_response
	print("[NetMan]: Received response to join request: \"%s\"" % response)
	_is_joining = false
	if response == UDP_OK:
		print("[NetMan]: The response was OK. Joining other server.")
		join_other_server()
		await multiplayer.connected_to_server
	elif response == UDP_SAME_TIME:
		print("[NetMan]: The response was SAME_TIME. Deciding who will be the server...")
		if my_ip < other_ip:
			print_rich("[NetMan]: I will be the [color=pink][b]server[/b][/color]. Creating server...")
			create_server()
			broadcast(UDP_SERVER_CREATED)
			await multiplayer.peer_connected
		else:
			print_rich("[NetMan]: I will be the [color=pink][b]client[/b][/color]. Requesting server...")
			broadcast(UDP_REQUEST_SERVER)
			await multiplayer.connected_to_server
	else:
		if response.is_empty():
			print("[NetMan]: Join request response timed out. Starting server.")
		else:
			print("[NetMan]: Join request received NO_SERVER. Starting server.")
		create_server()


func create_server() -> void:
	print("[NetMan]: Creating ENet server...")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT_GAME, 2)
	if error != OK:
		Debug.print_error("[NetMan]: Failed to start server. Error: %s" % error)
		return
	multiplayer.multiplayer_peer = peer
	_is_server_up = true
	print("[NetMan]: Server started successfully.")


func join_other_server() -> void:
	print("[NetMan]: Creating ENet client to join existing server...")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(other_ip, PORT_GAME)
	if error != OK:
		Debug.print_error("[NetMan]: Failed to create client. Error: %s" % error)
		return
	multiplayer.multiplayer_peer = peer
	_did_join_server = true
	print("[NetMan]: Client created successfully.")


#func _broadcast_status(...args: Array) -> void:
	#var argStr : String = UDP_STATUS
	#for arg in args:
		#argStr += ',' + str(arg)
	#_broadcast(argStr)


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

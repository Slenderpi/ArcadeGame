extends Node

## If true, NetworkManager will look for an ethernet IP to use.
## Otherwise, it will look for a wifi IP.
const USE_ETH_IP : bool = false
## If true, NetworkManager will print many more messages in the console.
const VERBOSE : bool = false

## The states of NetworkManager.
enum ENetworkManagerState {
	IDLE,
	SEARCHING,
	PAIRING,
	CONNECTED,
	
	CALLING,
	#WAITING_SERVER,
	#HOST,
	#CLIENT
}


#region SIGNALS

## 
signal connected(isMultiplayer: bool, isHost: bool)
## Emitted if connection to the peer has been lost.
signal disconnected

signal _search_result(result: String)




## Emitted when this devices receives a CALL and
## [member NetworkManager.can_versus] is true.
signal versus_peer_found
## Emitted when both devices have connected to each other via ENet.
signal server_started(multiplayer: bool)

#endregion

#region PORT CONSTANTS

## Port to use for discovery
const PORT_NETWORKING := 31983
## Port to use for the game
const PORT_GAME := 21983

#endregion

#region UDP STR CONSTANTS

## This string is appended to all packets sent over UDP.
## NetworkManager will expect packets it receives to have this header.
const UDPSTR_HEADER := &"VirtualOff"
## Sent when in the [enum ENetworkManagerState.CALLING] state.
const UDPSTR_CALL := &"CALL"
## Sent when in the [enum ENetworkManagerState.CALLING] state AND this
## NetworkManager receives a CALL AND there is someone playing.
const UDPSTR_RESPONSE := &"RESPONSE"
## Sent when inthe [enum ENetworkManagerState.CALLING] state AND this
## NetworkManager receives a CALL AND the game does not have a Player on it.
const UDPSTR_NOPLAY := &"NOPLAY"
## A server has been created. Request the other device to join.
const UDPSTR_SERVER_CREATED := &"SERVER_CREATED"
## Request the other device to create the server.
const UDPSTR_SERVER_REQUEST := &"SERVER_REQUEST"

#endregion

## Global IP when calling out to everyone on the network.
const GLOBAL_IP := &"255.255.255.255"

#region PUBLIC MEMBERS

var state := ENetworkManagerState.IDLE

var open_for_challengers : bool:
	get:
		return _open_for_challengers
	set(value):
		_open_for_challengers = value
var _open_for_challengers : bool = false

## An array of all currently known IPs on this device.
var my_local_ips : Array[String] = []
## The preferred IP of this device.
var my_ip : String
## The preferred IP of a peer's device.
var other_ip : String
## The peer ID of a peer.
var other_peer_id : int

## How long to wait between unanswered CALLs.
var call_retry_time : float = 1
## Maximum number of CALL tries.
var max_call_attempts : int = 3





## Set this value to tell NetworkManager whether or not this device can be
## challenged by another device for versus mode.[br]
## [br]
## [b]Example:[/b] no coin has been inserted on this device yet, so this value
## should be false.
## Then, a coin is inserted. This value should then get set to true.
var can_versus : bool = false

#endregion

#region PRIVATE MEMBERS

var _udp := PacketPeerUDP.new()

var _last_call_time : int = -10000
var _curr_call_attempts := 0

#endregion


#region NODE OVERRIDES

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _process(_delta: float) -> void:
	if state == ENetworkManagerState.CALLING:
		_call_for_peer()
	if _udp.get_available_packet_count() > 0:
		var packetStr := _udp.get_packet().get_string_from_ascii()
		var senderIp := _udp.get_packet_ip()
		if _udp_packet_is_valid(packetStr, senderIp):
			_process_udp_msg(senderIp, packetStr.trim_prefix(UDPSTR_HEADER + ',').split(','))

#endregion

#region PUBLIC METHODS

## Gets local IPs, preferred IP, and initializes UDP.
func init() -> void:
	Debug.print_info(Debug.HORIZONTAL_LINE_STR)
	Debug.print_info("[NetMan]: Initializing.")
	if VERBOSE:
		_print_local_interfaces()
	_set_local_ips()
	_init_udp()
	#state = ENetworkManagerState.CALLING
	#if VERBOSE:
	Debug.print_success("[NetMan]: Setup finished. Changing to IDLE state.")
	Debug.print_info(Debug.HORIZONTAL_LINE_STR)
	state = ENetworkManagerState.IDLE


## Tells the NetworkManager to start looking for a peer.[br][br]
## This function is asynchronous.[br][br]
## Returns "" if no peer found, otherwise returns their IP.
func find_peer() -> String:
	_curr_call_attempts = 0
	state = ENetworkManagerState.SEARCHING
	return await _search_result


### Tells the NetworkManager to start looking for a peer.[br][br]
### This function is asynchronous.[br][br]
### Returns "" if no peer found, otherwise returns their IP.
#func find_peer() -> String:
	#state = ENetworkManagerState.CALLING
	#return await _call_result


## Starts a server for singleplayer (i.e. an offline server).
## This triggers similar processes that [method NetworkManager.start_server] would.
func start_singleplayer_server() -> void:
	print("[NetMan]: start_singleplayer_server() called.")
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	other_peer_id = 0
	state = ENetworkManagerState.IDLE
	print("[NetMan]: Server started successfully.")
	#server_started.emit(false)
	connected.emit(false, true)


## Given a known peer IP, runs host/client negotiation + the ENet handshake.

## [signal NetworkManager.connected] fires once fully connected.
func pair_with_peer() -> void:
	print("[NetMan]: pair_with_peer() called.")
	state = ENetworkManagerState.PAIRING
	if my_ip > other_ip: # deterministic, arbitrary tiebreak
		print_rich("[NetMan]: I will be the [b][color=pink]host!")
		_create_server()
	else:
		print_rich("[NetMan]: I will be the [b][color=pink]client!")
		print("[NetMan]: Broadcasting SERVER_REQUEST.")
		_broadcast_server_request()
		_start_pairing_timeout()


func _start_pairing_timeout() -> void:
	var elapsed := 0.0
	while state == ENetworkManagerState.PAIRING and elapsed < call_retry_time * max_call_attempts:
		await get_tree().create_timer(call_retry_time).timeout
		elapsed += call_retry_time
		if state == ENetworkManagerState.PAIRING:
			_broadcast_server_request()  # retry
	if state == ENetworkManagerState.PAIRING:
		state = ENetworkManagerState.IDLE
		disconnected.emit()  # let GameStateManager know pairing failed


## Starts a server for multiplayer versus (i.e. an online server).
## The IP given in [param serverIp] should be the IP of the device that will
## become the server.[br][br]
## If this device is to become the [b][color=pink]server[/color][/b],
## it will create a server and broadcast [b]SERVER_CREATED[/b].[br][br]
## If this device is to become the [b][color=pink]client[/color][/b],
## it will broadcast a [b]SERVER_REQUEST[/b].[br][br]
## NetworkManager listens for either [b]SERVER_CREATED[/b] or [b]SERVER_REQUEST[/b], and then
## either joins the created server or creates one.[br][br]
## When the lobby is fully setup (i.e. the server is created AND the client has joined),
## the [signal NetworkManager.server_started] signal will be emitted.
#func start_server(serverIp: String) -> void:
	#print("[NetMan]: start_server() called.")
	#if serverIp == my_ip:
		#print_rich("[NetMan]: I will be the [b][color=pink]host!")
		#_create_server()
	#else:
		#print_rich("[NetMan]: I will be the [b][color=pink]client!")
		#print("[NetMan]: Broadcasting SERVER_REQUEST.")
		#_broadcast_server_request()


## Tears down any active connection and resets for a fresh session.
func reset() -> void:
	Debug.print_info("[NetMan]: reset() called.")
	if multiplayer.multiplayer_peer:
		Debug.print_info("[NetMan]: Closing multiplayer peer.")
		multiplayer.multiplayer_peer.close.call_deferred()
		multiplayer.set_deferred("multiplayer_peer", null)
	other_ip = ""
	other_peer_id = 0
	open_for_challengers = false
	state = ENetworkManagerState.IDLE


## Stops the server (or, if you're the client, closes the client). Resets
## the multiplayer_peer to null.[br][br]
## Also resets other internal properties so that another calling session is
## available.
#func close_server() -> void:
	#Debug.print_info("[NetMan]: Closing multiplayer peer.")
	#if multiplayer.multiplayer_peer:
		#multiplayer.multiplayer_peer.close.call_deferred()
		#multiplayer.set_deferred("multiplayer_peer", null)
	#else:
		#Debug.print_warning("[NetMan]: Attempted to close multiplayer peer but there is currently none set yet.")
	#other_ip = &""
	#other_peer_id = 0
	#_last_call_time = -10000
	#_curr_call_attempts = 0
	## TODO: MainScene should probably trigger returning to CALL state, and this code should instead go to IDLE
	#state = ENetworkManagerState.IDLE
	##state = ENetworkManagerState.CALLING

#endregion

#region ENET HELPERS

func _create_server() -> void:
	print("[NetMan]: Creating ENet server...")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT_GAME, 2)
	if error != OK:
		Debug.print_error("[NetMan]: Failed to start server. Error: %s" % error)
		return
	multiplayer.multiplayer_peer = peer
	print("[NetMan]: Server started successfully.")
	state = ENetworkManagerState.IDLE # TODO: what state should be next?
	_broadcast_server_created()


func _create_client() -> void:
	print("[NetMan]: Creating ENet client...")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(other_ip, PORT_GAME)
	if error != OK:
		Debug.print_error("[NetMan]: Failed to create client. Error: %s" % error)
		return
	multiplayer.multiplayer_peer = peer
	Debug.print_success("[NetMan]: Client created and joined successfully.")
	#state = ENetworkManagerState.CLIENT
	state = ENetworkManagerState.IDLE # TODO: what state should be next?

#endregion

#region MISC HELPERS

func _set_local_ips() -> void:
	my_local_ips.clear()
	var interfaces := IP.get_local_interfaces()
	for iface in interfaces:
		var addresses : Array = iface["addresses"]
		for addr in addresses: # TODO: Might remove
			my_local_ips.append(addr)
		if not my_ip.is_empty() or not _friendly_interface_req(iface["friendly"].to_lower()):
			continue
		if addresses.size() == 0:
			Debug.print_warning(
				"[NetMan]: Possible ethernet address found with 0 addresses. Index: %s | Name: %s | Friendly: %s" \
				% [iface["index"], iface["name"], iface["friendly"]]
			)
			continue
		var ipOption : String = addresses[0]
		if addresses.size() > 1:
			var addri := 0
			while addri < addresses.size() and ipOption.split('.').size() != 4:
				addri += 1
				ipOption = addresses[addri]
		my_ip = ipOption
	if VERBOSE:
		Debug.print_info("[NetMan]: Local ips on this device: \n%s" % str(my_local_ips))
	if my_ip.is_empty():
		Debug.print_error("[NetMan]: No ethernet IP was found!")
	else:
		Debug.print_notify("[NetMan]: Found my %s address: %s" % ["ETHERNET" if USE_ETH_IP else "WIFI", my_ip])


func _friendly_interface_req(friendlyLowered: String) -> bool:
	if USE_ETH_IP:
		return "eth" in friendlyLowered
	else:
		for c in friendlyLowered:
			if c.is_valid_int():
				return false
		return "wi-fi" in friendlyLowered or "wifi" in friendlyLowered

#endregion

#region UDP AND CALL PROCESSING

func _call_for_peer() -> void:
	var currTime := Time.get_ticks_msec()
	if currTime - _last_call_time >= call_retry_time * 1000:
		_curr_call_attempts += 1
		if _curr_call_attempts > max_call_attempts:
			state = ENetworkManagerState.IDLE
			print_rich("[color=orange][NetMan]: Call attempts have timed out. Firing _call_result with empty string.")
			_search_result.emit("")
		else:
			_last_call_time = currTime
			print("[NetMan]: Broadcasting CALL...")
			_broadcast_call()


func _process_udp_msg(senderIp: String, msgArgs: Array[String]) -> void:
	if msgArgs[0] == UDPSTR_CALL:
		Debug.print_success("[NetMan]: Received CALL from %s with preferred IP %s" % [senderIp, msgArgs[1]])
		#if can_versus:
		if open_for_challengers and state != ENetworkManagerState.CONNECTED:
			Debug.print_success("[NetMan]: can_versus is true. Replying with RESPONSE.")
			other_ip = msgArgs[1]
			#versus_peer_found.emit()
			_broadcast_response()
			pair_with_peer()
		else:
			print_rich("[color=orange][NetMan]: can_versus is false. Replying with NOPLAY.")
			_broadcast_noplay(msgArgs[1])
	elif msgArgs[0] == UDPSTR_RESPONSE:
		Debug.print_success("[NetMan]: Received RESPONSE from %s with preferred IP %s" % [senderIp, msgArgs[1]])
		other_ip = msgArgs[1]
		state = ENetworkManagerState.IDLE
		_search_result.emit(other_ip)
	elif msgArgs[0] == UDPSTR_NOPLAY:
		Debug.print_success("[NetMan]: Received NOPLAY from %s" % senderIp)
		if state == ENetworkManagerState.CALLING:
			state = ENetworkManagerState.IDLE
			_search_result.emit("")
		else:
			print("[NetMan]: NetworkManager is in IDLE state. The NOPLAY will be ignored.")
	elif msgArgs[0] == UDPSTR_SERVER_CREATED:
		Debug.print_success("[NetMan]: Received SERVER_CREATED from %s" % senderIp)
		_create_client()
	elif msgArgs[0] == UDPSTR_SERVER_REQUEST:
		Debug.print_success("[NetMan]: Received SERVER_REQUEST from %s" % senderIp)
		_create_server()
	else:
		print_rich("[NetMan]: Received unkown message from %s: %s" % [senderIp, str(msgArgs)])


func _udp_packet_is_valid(packetStr: String, senderIp: String) -> bool:
	if my_local_ips.has(senderIp):
		print("[NetMan]: Received my own message (ip: %s | message: %s)" % [senderIp, packetStr])
		return false
	elif not packetStr.begins_with(UDPSTR_HEADER):
		Debug.print_warning("[NetMan]: Received unrelated message (ip: %s | message: %s)" % [senderIp, packetStr])
		return false
	else:
		return true

#endregion

#region UDP BROADCASTING

func make_packet(message: String) -> String:
	return UDPSTR_HEADER + ',' + message


func _broadcast_call() -> void:
	_last_call_time = Time.get_ticks_msec()
	_udp.set_dest_address(GLOBAL_IP, PORT_NETWORKING)
	_udp.put_packet(make_packet(UDPSTR_CALL + ',' + my_ip).to_utf8_buffer())


func _broadcast_response() -> void:
	_udp.set_dest_address(other_ip, PORT_NETWORKING)
	_udp.put_packet(make_packet(UDPSTR_RESPONSE + ',' + my_ip).to_utf8_buffer())


func _broadcast_noplay(senderIp: String) -> void:
	_udp.set_dest_address(senderIp, PORT_NETWORKING)
	_udp.put_packet(make_packet(UDPSTR_NOPLAY).to_utf8_buffer())


func _broadcast_server_created() -> void:
	_udp.set_dest_address(other_ip, PORT_NETWORKING)
	_udp.put_packet(make_packet(UDPSTR_SERVER_CREATED).to_utf8_buffer())


func _broadcast_server_request() -> void:
	_udp.set_dest_address(other_ip, PORT_NETWORKING)
	_udp.put_packet(make_packet(UDPSTR_SERVER_REQUEST).to_utf8_buffer())


func _init_udp() -> void:
	var error = _udp.bind(PORT_NETWORKING)
	if error != OK:
		Debug.print_error("[NetMan]: Encountered an error when binding to UDP socket for discovery: %s" % error)
		return
	_udp.set_broadcast_enabled(true)
	if VERBOSE:
		print("[NetMan]: UDP setup on port %d." % _udp.get_local_port())

#endregion

#region SIGNAL BINDING

func _on_peer_connected(peerId: int):
	Debug.print_notify("[NetMan]: peer_connected signaled with peerId %d." % peerId)
	if peerId != multiplayer.get_unique_id():
		other_peer_id = peerId
		#server_started.emit(true)
		state = ENetworkManagerState.CONNECTED
		open_for_challengers = false
		connected.emit(true, multiplayer.is_server())


func _on_peer_disconnected(peerId: int):
	Debug.print_notify("[NetMan]: peer_disconnected signaled with peerId %d." % peerId)
	disconnected.emit()

#endregion

#region DEBUGGING

func _print_local_interfaces() -> void:
	var interfaces := IP.get_local_interfaces()
	Debug.print_info("[NetMan]: PRINTING LOCAL INTERFACES. Unorganized listing:")
	print(interfaces)
	print(Debug.HORIZONTAL_LINE_STR)
	for interface in interfaces:
		print(
			"index: ", interface["index"], '\n',
			"name: ", interface["name"], '\n',
			"friendly: ", interface["friendly"], '\n',
			"addresses: ", interface["addresses"], '\n'
		)
	Debug.print_info("Done printing interfaces.")
	print(Debug.HORIZONTAL_LINE_STR)
	print()

#endregion

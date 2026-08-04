extends Node


## The states of NetworkManager.
enum ENetworkManagerState {
	IDLE,
	CALLING,
	WAITING_SERVER,
	HOST,
	CLIENT
}


## Emitted when another Peer is found, which occurs when either a CALL or
## a RESPONSE is received.
signal found_peer
## Emitted when another Peer joined through ENet. For the host, this is when
## the server is created. For the client, this is when they have successfully
## connected to the server.[br]
## [br]
## [code]peerId[/code]: the Id of the Peer that joined.
signal player_connected(peerId: int)
## Emitted when another Peer left through ENet.[br]
## [br]
## [code]peerId[/code]: the Id of the Peer that left.
signal player_disconnected(peerId: int)


## Emitted when this devices receives a CALL and
## [member NetworkManager.can_versus] is true.
signal versus_peer_found(otherIp: String) # TODO
## Emitted when both devices have connected to each other via ENet.
signal server_started(multiplayer: bool) # TODO
## Emitted if connection to the peer has been lost.
signal disconnected

signal _call_result(result: String)


## Port to use for discovery
const PORT_NETWORKING := 31983
## Port to use for the game
const PORT_GAME := 21983

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
## Sent by the NetworkManager after it's started its server.
const UDPSTR_SERVER_START := &"SERVER_START" # TODO: delete?
const UDPSTR_SERVER_CREATED := &"SERVER_CREATED"
const UDPSTR_SERVER_REQUEST := &"SERVER_REQUEST"

## Global IP when calling out to everyone on the network.
const GLOBAL_IP := &"255.255.255.255"


var state := ENetworkManagerState.IDLE

## Set this value to tell NetworkManager whether or not this device can be
## challenged by another device for versus mode.[br]
## [br]
## [b]Example:[/b] no coin has been inserted on this device yet, so this value
## should be false.
## Then, a coin is inserted. This value should then get set to true.
var can_versus : bool = false

var udp := PacketPeerUDP.new()
var peer := ENetMultiplayerPeer.new()

var my_local_ips : Array[String] = []
var my_ip : String
var other_ip : String
var other_peer_id : int

## How long to wait between unanswered CALLs.
var call_retry_time : float = 1
## Maximum number of CALL tries.
var max_call_attempts : int = 3
var _last_call_time : int = -10000 # TODO: reset value
var _curr_call_attempts := 0 # TODO: reset value


func _ready() -> void:
	multiplayer.peer_connected.connect(func(peerId: int):
		print_rich("[color=orange]peer_connected fired with peerId %d." % peerId)
		if peerId != peer.get_unique_id():
			other_peer_id = peer.get_unique_id()
			server_started.emit(true)
	)
	multiplayer.peer_disconnected.connect(func(peerId: int):
		print_rich("[color=orange]peer_disconnected fired with peerId %d." % peerId)
		disconnected.emit()
	)
	#multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(func():
		print_rich("[color=orange]server_disconnected fired.")
		disconnected.emit()
	)
	#multiplayer.peer_connected.connect(_on_peer_connected)
	#multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	#multiplayer.connected_to_server.connect(_on_connected_to_server)
	#multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	_print_local_interfaces()
	_set_local_ips()
	var error = udp.bind(PORT_NETWORKING)
	if error != OK:
		Debug.print_error("Encountered an error when binding to UDP socket for discovery: %s" % error)
		return
	udp.set_broadcast_enabled(true)
	print("UDP setup on port %d." % udp.get_local_port())
	#state = ENetworkManagerState.CALLING
	print_rich("[color=green]NetworkManager setup finished. Changing to IDLE state.\n\
-----------------------------------------------------------------------------\
\n")
	state = ENetworkManagerState.IDLE


func _process(_delta: float) -> void:
	if state == ENetworkManagerState.CALLING:
		var currTime := Time.get_ticks_msec()
		if currTime - _last_call_time >= call_retry_time * 1000:
			_curr_call_attempts += 1
			if _curr_call_attempts > max_call_attempts:
				state = ENetworkManagerState.IDLE
				print_rich("[color=orange]Call attempts have timed out. Firing _call_result with empty string.")
				_call_result.emit("")
			else:
				_last_call_time = currTime
				print("Broadcasting CALL...")
				_broadcast_call()
		
	if udp.get_available_packet_count() > 0:
		var packetArr := udp.get_packet()
		var packetStr := packetArr.get_string_from_ascii()
		
		var senderIp := udp.get_packet_ip()
		if my_local_ips.has(senderIp):
			print("Received my own message (ip: %s | message: %s)" % [senderIp, packetStr])
			return
		elif not packetStr.begins_with(UDPSTR_HEADER):
			Debug.print_warning("Received unrelated message (ip: %s | message: %s)" % [senderIp, packetStr])
			return
		
		var msgArgs := packetStr.trim_prefix(UDPSTR_HEADER + ',').split(',')
		
		if msgArgs[0] == UDPSTR_CALL:
			print_rich("[color=green]Received CALL from %s with preferred IP %s" % [senderIp, msgArgs[1]])
			senderIp = msgArgs[1]
			if can_versus:
				print_rich("[color=green]can_versus is true. Replying with RESPONSE.")
				other_ip = msgArgs[1]
				versus_peer_found.emit(other_ip)
				_broadcast_response()
			else:
				print_rich("[color=orange]can_versus is false. Replying with NOPLAY.")
				_broadcast_noplay(senderIp)
		elif msgArgs[0] == UDPSTR_RESPONSE:
			print_rich("[color=green]Received RESPONSE from %s with preferred IP %s" % [senderIp, msgArgs[1]])
			other_ip = msgArgs[1]
			state = ENetworkManagerState.IDLE
			_call_result.emit(other_ip)
		elif msgArgs[0] == UDPSTR_NOPLAY:
			print_rich("[color=green]Received NOPLAY from %s" % senderIp)
			state = ENetworkManagerState.IDLE
			_call_result.emit("")
		elif msgArgs[0] == UDPSTR_SERVER_CREATED:
			print_rich("[color=green]Received SERVER_CREATED from %s" % senderIp)
			_create_client()
		elif msgArgs[0] == UDPSTR_SERVER_REQUEST:
			print_rich("[color=green]Received SERVER_REQUEST from %s" % senderIp)
			_create_server()
		else:
			print_rich("Received unkown message from %s: %s" % [senderIp, str(msgArgs)])
		#match state:
			#ENetworkManagerState.CALLING:
				#print_rich("[color=green]Received message from %s: %s" % [senderIp, str(msgArgs)])
				#if msgArgs[0] == UDPSTR_CALL
				#WebRTCMultiplayerPeer
		
		
		#match state:
			#ENetworkManagerState.CALLING:
				#if msgArgs[0] == UDPSTR_CALL:
					#state = ENetworkManagerState.WAITING_SERVER
					#print_rich("[color=green]Received CALL from %s! I will be a client." % senderIp)
					#_on_found_peer(senderIp)
					#_broadcast_response()
				#elif msgArgs[0] == UDPSTR_RESPONSE:
					#print_rich("[color=green]Received RESPONSE from %s! I will be the host." % senderIp)
					#_on_found_peer(senderIp)
					#_start_server()
				#else:
					#print_rich("[color=green]Received unrecognized message from %s:[/color] %s" % [senderIp, str(msgArgs)])
			#ENetworkManagerState.WAITING_SERVER:
				#if msgArgs[0] == UDPSTR_SERVER_START:
					#print_rich("[color=green]Received SERVER_START from %s!" % senderIp)
					#_create_client_peer()
			#ENetworkManagerState.IDLE, ENetworkManagerState.HOST, ENetworkManagerState.CLIENT:
				#print_rich("Received message from %s: %s" % [senderIp, str(msgArgs)])


#func set_to_solo() -> void:
	#state = ENetworkManagerState.IDLE
	#peer.disconnect_peer()


func find_peer() -> String:
	state = ENetworkManagerState.CALLING
	return await _call_result
	#state = ENetworkManagerState.CALLING
	#_broadcast_call()


func start_singleplayer_server() -> void:
	Debug.print_info("NetworkManager.start_singleplayer_server() called.")
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	other_peer_id = 0
	print_rich("[color=green]Server started successfully.")
	#can_versus = false
	state = ENetworkManagerState.IDLE # TODO: what state should be next?
	server_started.emit(false)


func start_server(serverIp: String) -> void:
	Debug.print_info("NetworkManager.start_server() called.")
	if serverIp == my_ip:
		print_rich("I will be the [color=pink]host!")
		_create_server()
	else:
		print_rich("I will be the [color=pink]client!")
		print("Broadcasting SERVER_REQUEST.")
		_broadcast_server_request()


func _broadcast_call() -> void:
	_last_call_time = Time.get_ticks_msec()
	udp.set_dest_address(GLOBAL_IP, PORT_NETWORKING)
	udp.put_packet(make_packet(UDPSTR_CALL + ',' + my_ip).to_utf8_buffer())


func _broadcast_response() -> void:
	udp.set_dest_address(other_ip, PORT_NETWORKING)
	udp.put_packet(make_packet(UDPSTR_RESPONSE + ',' + my_ip).to_utf8_buffer())


func _broadcast_noplay(senderIp: String) -> void:
	udp.set_dest_address(senderIp, PORT_NETWORKING)
	udp.put_packet(make_packet(UDPSTR_NOPLAY).to_utf8_buffer())


func _broadcast_hello() -> void:
	udp.set_dest_address(other_ip, PORT_NETWORKING)
	udp.put_packet(make_packet("Hello!").to_utf8_buffer())


func _broadcast_server_created() -> void:
	udp.set_dest_address(other_ip, PORT_NETWORKING)
	udp.put_packet(make_packet(UDPSTR_SERVER_CREATED).to_utf8_buffer())


func _broadcast_server_request() -> void:
	udp.set_dest_address(other_ip, PORT_NETWORKING)
	udp.put_packet(make_packet(UDPSTR_SERVER_REQUEST).to_utf8_buffer())


#func _broadcast_server_start() -> void:
	#udp.set_dest_address(other_ip, PORT_NETWORKING)
	#udp.put_packet(make_packet(UDPSTR_SERVER_START).to_utf8_buffer())


func make_packet(message: String) -> String:
	return UDPSTR_HEADER + ',' + message


## Stops the server. Only the host should call this.
func close_server() -> void:
	assert(state == ENetworkManagerState.HOST, "close_server() caller was not in HOST state. Only the HOST should call this.")
	peer.close()
	multiplayer.multiplayer_peer = null
	# TODO: MainScene should probably trigger returning to CALL state, and this code should instead go to IDLE
	state = ENetworkManagerState.CALLING


### Starts the server. The NetworkManager that will be the host should call this.
#func _start_server() -> void: # TODO: delete?
	#var error := peer.create_server(PORT_GAME, 2)
	#if error != OK:
		#Debug.print_error("Failed to start server. Error: %s" % error)
		#return
	#multiplayer.multiplayer_peer = peer
	#state = ENetworkManagerState.HOST
	#print_rich("[color=green]Server started successfully.")
	##_broadcast_server_start()
	#player_connected.emit(1)


func _create_server() -> void:
	print("Creating ENet server...")
	var error := peer.create_server(PORT_GAME, 2)
	if error != OK:
		Debug.print_error("Failed to start server. Error: %s" % error)
		return
	multiplayer.multiplayer_peer = peer
	print_rich("[color=green]Server started successfully.")
	#can_versus = false
	state = ENetworkManagerState.IDLE # TODO: what state should be next?
	_broadcast_server_created()


#func _create_client_peer() -> void:
func _create_client() -> void:
	print("Creating ENet client...")
	var error := peer.create_client(other_ip, PORT_GAME)
	if error != OK:
		Debug.print_error("Failed to create client. Error: %s" % error)
		return
	multiplayer.multiplayer_peer = peer
	other_peer_id = peer.get_unique_id()
	print_rich("[color=green]Client created and joined successfully.")
	#state = ENetworkManagerState.CLIENT
	#can_versus = false
	state = ENetworkManagerState.IDLE # TODO: what state should be next?
	#player_connected.emit(peer.get_unique_id())
	# TODO: server_started needs to be emitted on probably the peer_connected signal


#func _on_peer_connected(id: int) -> void:
	#print("Peer connected. Id: %d" % id)
	#player_connected.emit(id)
#
#
#func _on_peer_disconnected(id: int) -> void:
	#print("Peer disconnected. Id: %d" % id)
	#if state == ENetworkManagerState.HOST and multiplayer.get_peers().size() == 0:
		#Debug.print_info("Returning to CALL state.")
		#close_server()
	#player_disconnected.emit(id)`
#
#
#func _on_connected_to_server() -> void:
	#print("Connected to server.")
	#player_connected.emit(peer.get_unique_id())
#
#
#func _on_server_disconnected() -> void:
	## TODO: MainScene should probably trigger returning to CALL state, and this code should instead go to IDLE
	#print("Server disconnected. Returning to CALL state.")
	#state = ENetworkManagerState.CALLING


#func _on_found_peer(senderIp: String) -> void:
	#other_ip = senderIp
	#found_peer.emit()


func _set_local_ips() -> void:
	my_local_ips.clear()
	var interfaces := IP.get_local_interfaces()
	for iface in interfaces:
		var addresses : Array = iface["addresses"]
		for addr in addresses: # TODO: Might remove
			my_local_ips.append(addr)
		if not my_ip.is_empty() or "eth" not in iface["friendly"].to_lower():
			continue
		if addresses.size() == 0:
			Debug.print_warning(
				"Possible ethernet address found with 0 addresses. Index: %s | Name: %s | Friendly: %s" \
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
		print_rich("[color=green]Found my ethernet address: ", my_ip)
		#for addr : String in addresses:
			#if addr.split('.').size() == 4:
				#if not my_ip.is_empty():
					#Debug.print_warning("Found another ethernet IPv4 address: %s" % addr)
				#my_ip = addr
				#print_rich("[color=green]Found my ethernet ipv4: ", addr)
				#return
		#for addr in iface["addresses"]:
			#my_local_ips.append(addr)
		#var friendly : String = iface["friendly"].to_lower()
		#if friendly.begins_with("eth"):
			#for addr in iface["addresses"]:
				#my_local_ips.append(addr)
	if my_ip.is_empty():
		Debug.print_error("No ethernet IP was found!")
	Debug.print_info("Local ips on this device: \n%s" % str(my_local_ips))


func _exit_tree() -> void:
	udp.close()


#func _input(event: InputEvent) -> void:
	#if event is InputEventKey:
		#if event.pressed and event.keycode == KEY_J:
			#print("J KEY PRESSED")
			#_broadcast_call()


#func _input(event: InputEvent) -> void:
	#if event is InputEventKey:
		#if event.pressed and event.keycode == KEY_Y:
			#match state:
				#ENetworkManagerState.CALLING:
					#_broadcast_call()
				#ENetworkManagerState.WAITING_SERVER, ENetworkManagerState.IDLE, ENetworkManagerState.HOST, ENetworkManagerState.CLIENT:
					##_broadcast_call()
					#_broadcast_hello()


func _print_local_interfaces() -> void:
	var interfaces := IP.get_local_interfaces()
	Debug.print_info("PRINTING LOCAL INTERFACES. Unorganized listing:")
	print(interfaces)
	Debug.print_info("-----------------------------------------------------------------------------")
	for interface in interfaces:
		print(
			"index: ", interface["index"], '\n',
			"name: ", interface["name"], '\n',
			"friendly: ", interface["friendly"], '\n',
			"addresses: ", interface["addresses"], '\n'
		)
	Debug.print_info("Done printing interfaces.\n-----------------------------------------------------------------------------\n")

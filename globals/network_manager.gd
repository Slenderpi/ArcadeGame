extends Node


## NetworkManager state.
enum ENetworkManagerState {
	IDLE,
	CALLING,
	HOST,
	CLIENT
}


## Port to use for discovery
const PORT_NETWORKING := 8000
## Port to use for the game
const PORT_GAME := 7000

const UDPSTR_HEADER := &"VirtualOn"
const UDPSTR_CALL := &"CALL"
const UDPSTR_RESPONSE := &"RESPONSE"
#const UDPSTR_HOST := &"HOST"
#const UDPSTR_CLIENT := &"CLIENT"
#const UDPSTR_


var state := ENetworkManagerState.IDLE

var udp := PacketPeerUDP.new()
var peer := ENetMultiplayerPeer.new()

var my_local_ips : Array[String] = []
var other_ip : String


func _ready() -> void:
	#_print_local_interfaces()
	_set_local_ips()
	var error = udp.bind(PORT_NETWORKING)
	if error != OK:
		Debug.print_error("Encountered an error when binding to UDP socket for discovery: %s" % error)
		return
	udp.set_broadcast_enabled(true)
	
	state = ENetworkManagerState.CALLING


func _process(_delta: float) -> void:
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
		
		match state:
			ENetworkManagerState.CALLING:
				if msgArgs[0] == UDPSTR_CALL:
					other_ip = senderIp
					state = ENetworkManagerState.IDLE
					print_rich("[color=green]Received CALL from %s! I will be a client." % other_ip)
					_broadcast_response()
				elif msgArgs[0] == UDPSTR_RESPONSE:
					other_ip = senderIp
					state = ENetworkManagerState.IDLE
					print_rich("[color=green]Received RESPONSE from %s! I will be a server." % other_ip)
				else:
					print_rich("[color=green]Received unrecognized message from %s:[/color] %s" % [other_ip, str(msgArgs)])
			ENetworkManagerState.IDLE, ENetworkManagerState.HOST, ENetworkManagerState.CLIENT:
				print_rich("Not in calling state, but received message from %s: %s" % [other_ip, str(msgArgs)])


func _broadcast_call() -> void:
	udp.set_dest_address("255.255.255.255", PORT_NETWORKING)
	udp.put_packet(make_packet(UDPSTR_CALL).to_utf8_buffer())


func _broadcast_response() -> void:
	udp.set_dest_address(other_ip, PORT_NETWORKING)
	udp.put_packet(make_packet(UDPSTR_RESPONSE).to_utf8_buffer())


func _broadcast_hello() -> void:
	udp.set_dest_address(other_ip, PORT_NETWORKING)
	udp.put_packet(make_packet("Hello!").to_utf8_buffer())


func make_packet(message: String) -> String:
	return UDPSTR_HEADER + ',' + message


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_Y:
			match state:
				ENetworkManagerState.CALLING:
					_broadcast_call()
				ENetworkManagerState.IDLE, ENetworkManagerState.HOST, ENetworkManagerState.CLIENT:
					_broadcast_hello()


func _set_local_ips() -> void:
	my_local_ips.clear()
	var interfaces := IP.get_local_interfaces()
	for iface in interfaces:
		for addr in iface["addresses"]:
			my_local_ips.append(addr)
		#var friendly : String = iface["friendly"].to_lower()
		#if friendly.begins_with("eth"):
			#for addr in iface["addresses"]:
				#my_local_ips.append(addr)
	Debug.print_info("Local ips on this device: \n%s" % str(my_local_ips))


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

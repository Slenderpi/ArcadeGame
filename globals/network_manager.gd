extends Node


## NetworkManager state.
enum State {
	IDLE,
	SEARCHING,
	HOST,
	CLIENT
}


## Port to use for discovery
const PORT_NETWORKING := 8000
## Port to use for the game
const PORT_GAME := 7000

const UDPSTR_DISCOVERY := &"VIRTUAL ON,DISCOVERY"
const UDPSTR_HOST := &"VIRTUAL ON,HOST"
const UDPSTR_CLIENT := &"VIRTUAL ON,CLIENT"
#const UDPSTR_


var state := State.IDLE

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
	
	state = State.SEARCHING


func _process(_delta: float) -> void:
	if udp.get_available_packet_count() > 0:
		var array_bytes := udp.get_packet()
		var sender_ip := udp.get_packet_ip()
		if my_local_ips.has(sender_ip):
			print("Received my own message (ip: %s | message: %s)" % [sender_ip, udp.get_packet().get_string_from_ascii()])
			return
		
		other_ip = sender_ip
		
		var packet_string := array_bytes.get_string_from_ascii()
		print_rich("[color=green]Received message from %s:[/color] %s" % [sender_ip, packet_string])
		state = State.IDLE


func _broadcast_discovery() -> void:
	udp.set_dest_address("255.255.255.255", PORT_NETWORKING)
	udp.put_packet(UDPSTR_DISCOVERY.to_utf8_buffer())


func _broadcast_hello() -> void:
	udp.set_dest_address(other_ip, PORT_NETWORKING)
	udp.put_packet(("Hello!").to_utf8_buffer())


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_Y:
			match state:
				State.SEARCHING:
					_broadcast_discovery()
				State.IDLE, State.HOST, State.CLIENT:
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
	print_rich("[color=cyan]Local ips set for this device:\n", my_local_ips)


func _print_local_interfaces() -> void:
	var interfaces := IP.get_local_interfaces()
	print_rich(
		"[color=cyan]PRINTING LOCAL INTERFACES. Unorganized listing:[/color]\n%s\n[color=cyan]-----------------------------------------------------------------------------" \
			% interfaces)
	for interface in interfaces:
		print("index: ", interface["index"])
		print("name: ", interface["name"])
		print("friendly: ", interface["friendly"])
		print("addresses: ", interface["addresses"])
		print()
	print_rich("[color=cyan]Done printing interfaces.\n-----------------------------------------------------------------------------\n")

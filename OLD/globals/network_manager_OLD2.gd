## NetworkManager (autoload)
##
## Facade over LAN peer discovery + ENet session setup. Talks to the rest
## of the game ONLY via signals -- it has no knowledge of GameStateManager,
## States, or anything else upstream. GameStateManager listens to these
## signals and translates them into fsm events; that's the only bridge.
##
## Discovery model: every machine continuously broadcasts its own status
## (CLOSED/OPEN/BUSY) at a fixed interval, and continuously listens for
## the same from others, maintaining a live PeerRoster. This means
## "finding a peer" is just reading an already-warm table, not an
## active search -- so joining feels immediate rather than requiring
## a visible "searching..." step.
extends Node

#region CONFIG

## If true, prints verbose debug logs.
const VERBOSE : bool = false

## Ports.
const PORT_DISCOVERY := 31983
const PORT_GAME := 21983

## Broadcast target on the direct-link subnet. If you move to a switch
## with multiple cabinets on a shared subnet, this still works as long
## as they all share a subnet broadcast address; for anything fancier
## (routed segments), switch this to the subnet's specific broadcast
## address or move to multicast.
const BROADCAST_IP := "192.168.31.255"

## How often to broadcast our own status.
const HEARTBEAT_INTERVAL := 0.5

## How long to wait for a CLAIM_ACK before giving up on a claim attempt.
const CLAIM_TIMEOUT := 1.0

## How long to wait for the ENet handshake (SERVER_CREATED/REQUEST ->
## peer_connected) to complete before giving up on a pairing attempt.
const PAIRING_TIMEOUT := 5.0

#endregion

#region PROTOCOL STRINGS

const UDPSTR_HEADER := "VirtualOff"
const MSG_STATUS := "STATUS"
const MSG_CLAIM := "CLAIM"
const MSG_CLAIM_ACK := "CLAIM_ACK"
const MSG_SERVER_CREATED := "SERVER_CREATED"
const MSG_SERVER_REQUEST := "SERVER_REQUEST"

#endregion

#region SIGNALS

## Fired once ENet reports the peer is actually connected.
signal connection_established(is_multiplayer: bool, is_host: bool)
## Fired if a connected session drops, OR if a pairing/claim attempt
## fails/times out before ever connecting.
signal connection_lost

#endregion

#region STATE

enum EStatus { CLOSED, OPEN, BUSY }

var my_ip : String = ""
var other_ip : String = ""
var other_peer_id : int = 0

var _status : int = EStatus.CLOSED
var _roster := PeerRoster.new()
var _udp := PacketPeerUDP.new()

var _heartbeat_timer : float = 0.0
var _claim_ack_waiters := {}   # ip (String) -> Signal-like Callable resolution via _claim_result
var _claim_result : Signal
var _pairing_active := false

#endregion


#region NODE OVERRIDES

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_load_config_ip()
	_init_udp()


func _process(delta: float) -> void:
	_poll_udp()
	if _status != EStatus.CLOSED:
		_heartbeat_timer -= delta
		if _heartbeat_timer <= 0.0:
			_heartbeat_timer = HEARTBEAT_INTERVAL
			_broadcast_status()

#endregion


#region PUBLIC API

## Call once when a coin-start begins a new play session. Starts this
## machine advertising itself as OPEN (available to be joined).
func begin_session() -> void:
	_status = EStatus.OPEN
	_heartbeat_timer = 0.0  # broadcast immediately rather than waiting a full interval


## States call this to toggle whether a mid-session join is currently
## acceptable (true at Character Select / Results, false during Combat).
## Has no effect if no session is active or a peer is already connected.
func set_open_for_challengers(open: bool) -> void:
	if _status != EStatus.CLOSED and other_peer_id == 0:
		_status = EStatus.OPEN if open else EStatus.BUSY


## Ends the current session entirely: closes any ENet connection, stops
## advertising, clears roster entry for the old peer. Called on return
## to Attract mode.
func end_session() -> void:
	_status = EStatus.CLOSED
	_pairing_active = false
	if not other_ip.is_empty():
		_roster.remove(other_ip)
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close.call_deferred()
		multiplayer.set_deferred("multiplayer_peer", null)
	other_ip = ""
	other_peer_id = 0


## Synchronous lookup -- the roster is already warm from continuous
## listening, so this never blocks. Returns "" if nobody is open.
func find_open_peer() -> String:
	return _roster.find_open_peer()


## Starts a fully local (offline) session -- no networking involved.
func start_as_singleplayer() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	other_peer_id = 0
	connection_established.emit(false, true)


## Attempts to claim a peer the roster believes is open, then runs the
## full ENet pairing handshake. Await this. Resolves true if a full
## connection was established, false if the claim was rejected/timed
## out (caller should fall back to start_as_singleplayer()).
func try_claim(peer_ip: String) -> bool:
	if VERBOSE:
		print("[NetMan]: Attempting to claim %s" % peer_ip)
	_send(peer_ip, MSG_CLAIM)

	var acked := false
	var elapsed := 0.0
	var ack_signal_name := "_claim_ack_%s" % peer_ip.replace(".", "_")
	# Simplest robust wait: poll a dictionary flag set by _process_udp_msg,
	# rather than juggling one-off Signals per IP.
	_claim_ack_waiters[peer_ip] = null  # null = pending
	while elapsed < CLAIM_TIMEOUT:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if _claim_ack_waiters.get(peer_ip) != null:
			acked = _claim_ack_waiters[peer_ip]
			break
	_claim_ack_waiters.erase(peer_ip)

	if not acked:
		if VERBOSE:
			print("[NetMan]: Claim on %s failed or timed out." % peer_ip)
		_roster.remove(peer_ip)
		return false

	other_ip = peer_ip
	_roster.remove(peer_ip)
	return await _run_pairing()

#endregion


#region PAIRING / ENET

func _run_pairing() -> bool:
	_pairing_active = true
	if my_ip > other_ip:
		_create_server()
	else:
		_broadcast_server_request_to(other_ip)

	var elapsed := 0.0
	while _pairing_active and elapsed < PAIRING_TIMEOUT:
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	if not _pairing_active:
		return true  # _on_peer_connected already cleared this flag on success

	# Timed out.
	_pairing_active = false
	Debug.print_error("[NetMan]: Pairing with %s timed out." % other_ip)
	connection_lost.emit()
	return false


func _create_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT_GAME, 2)
	if error != OK:
		Debug.print_error("[NetMan]: Failed to start server. Error: %s" % error)
		_pairing_active = false
		return
	multiplayer.multiplayer_peer = peer
	if VERBOSE:
		print("[NetMan]: ENet server created.")
	_send(other_ip, MSG_SERVER_CREATED)


func _create_client() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(other_ip, PORT_GAME)
	if error != OK:
		Debug.print_error("[NetMan]: Failed to create client. Error: %s" % error)
		_pairing_active = false
		return
	multiplayer.multiplayer_peer = peer
	if VERBOSE:
		print("[NetMan]: ENet client created, joining %s." % other_ip)

#endregion


#region UDP -- SEND

func _send(ip: String, message: String) -> void:
	_udp.set_dest_address(ip, PORT_DISCOVERY)
	_udp.put_packet((UDPSTR_HEADER + "," + message).to_utf8_buffer())


func _broadcast_status() -> void:
	var status_str : String = ["CLOSED", "OPEN", "BUSY"][_status]
	_udp.set_dest_address(BROADCAST_IP, PORT_DISCOVERY)
	_udp.put_packet((UDPSTR_HEADER + "," + MSG_STATUS + "," + my_ip + "," + status_str).to_utf8_buffer())


func _broadcast_server_request_to(ip: String) -> void:
	_send(ip, MSG_SERVER_REQUEST)

#endregion


#region UDP -- RECEIVE

func _poll_udp() -> void:
	while _udp.get_available_packet_count() > 0:
		var packet_str := _udp.get_packet().get_string_from_utf8()
		var sender_ip := _udp.get_packet_ip()
		if sender_ip == my_ip:
			continue  # our own broadcast, ignore
		if not packet_str.begins_with(UDPSTR_HEADER):
			continue
		var args := packet_str.trim_prefix(UDPSTR_HEADER + ",").split(",")
		_process_udp_msg(sender_ip, args)


func _process_udp_msg(sender_ip: String, args: PackedStringArray) -> void:
	match args[0]:
		MSG_STATUS:
			# args[1] = sender's self-reported IP (may differ from sender_ip
			# if NAT/multi-homed; we trust their self-reported value since
			# that's what we'd need to dial back)
			_roster.update(args[1], args[2])

		MSG_CLAIM:
			if _status == EStatus.OPEN:
				_status = EStatus.BUSY  # provisional lock, guards against a double-claim race
				other_ip = sender_ip
				_send(sender_ip, MSG_CLAIM_ACK + ",1")
				_run_pairing()  # fire-and-forget on this side; connection_established will follow
			else:
				_send(sender_ip, MSG_CLAIM_ACK + ",0")

		MSG_CLAIM_ACK:
			if _claim_ack_waiters.has(sender_ip):
				_claim_ack_waiters[sender_ip] = (args[1] == "1")

		MSG_SERVER_CREATED:
			_create_client()

		MSG_SERVER_REQUEST:
			_create_server()

		_:
			if VERBOSE:
				print("[NetMan]: Unknown message from %s: %s" % [sender_ip, str(args)])

#endregion


#region SIGNAL HANDLERS

func _on_peer_connected(peer_id: int) -> void:
	if peer_id == multiplayer.get_unique_id():
		return
	other_peer_id = peer_id
	_pairing_active = false
	_status = EStatus.BUSY  # full -- no more room, stop advertising OPEN
	connection_established.emit(true, multiplayer.is_server())


func _on_peer_disconnected(_peer_id: int) -> void:
	other_peer_id = 0
	connection_lost.emit()

#endregion


#region SETUP HELPERS

func _load_config_ip() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("res://cabinet.cfg") == OK:
		my_ip = cfg.get_value("network", "my_ip", "")
	if my_ip.is_empty():
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
		Debug.print_success("[NetMan]: Using configured IP %s (confirmed live)." % my_ip)
	else:
		Debug.print_error("[NetMan]: Configured IP %s not found on any local interface! Check the Ethernet cable / static IP setting." % my_ip)


func _init_udp() -> void:
	var error := _udp.bind(PORT_DISCOVERY)
	if error != OK:
		Debug.print_error("[NetMan]: Failed to bind UDP discovery socket: %s" % error)
		return
	_udp.set_broadcast_enabled(true)
	if VERBOSE:
		print("[NetMan]: UDP discovery bound on port %d." % PORT_DISCOVERY)

#endregion

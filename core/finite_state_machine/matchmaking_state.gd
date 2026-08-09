extends StateBase
class_name MatchmakingState
## Attempts to find a peer to connect to.

const SERVER_CONNECTION_SUCCEEDED = 1
const SERVER_CONNECTION_FAILED = 2


var _connect_status := 0
var _connection_attempt_time : int


func enter(_payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Primary][Matchmaking]: >> enter()")
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(NetworkManager.other_ip, NetworkManager.PORT_GAME)
	if error != OK:
		Debug.print_error("[State][Primary][Matchmaking]: Failed to create client. Error: %s" % error)
		return
	_connection_attempt_time = Time.get_ticks_msec()
	NetworkManager.multiplayer.connection_failed.connect(_on_connection_failed, CONNECT_ONE_SHOT)
	NetworkManager.multiplayer.connected_to_server.connect(_on_connected_to_server, CONNECT_ONE_SHOT)
	NetworkManager.multiplayer.multiplayer_peer = peer


func update(_delta: float) -> void:
	if _connect_status == SERVER_CONNECTION_SUCCEEDED:
		Debug.print_success("[State][Primary][Matchmaking]: Connection successful.")
		_connect_status = 3
		finished.emit()
	elif _connect_status == SERVER_CONNECTION_FAILED:
		Debug.print_warning("[State][Primary][Matchmaking]: Connection failed.")
		_connect_status = 3
		finished.emit()
	elif _connect_status == 0 && Time.get_ticks_msec() - _connection_attempt_time > 3 * 1000:
		NetworkManager.multiplayer.connected_to_server.disconnect(_on_connected_to_server)
		NetworkManager.multiplayer.connection_failed.disconnect(_on_connection_failed)
		Debug.print_warning("[State][Primary][Matchmaking]: No peer found for 3 * 1000 msec ticks. Going singleplayer.")
		var peer := ENetMultiplayerPeer.new()
		var error := peer.create_server(NetworkManager.PORT_GAME, 2)
		if error != OK:
			Debug.print_error("[State][Primary][Matchmaking]: Failed to create server. Error: %s" % error)
		else:
			Debug.print_notify("[State][Primary][Matchmaking]: Singleplayer server created!")
			NetworkManager.multiplayer.multiplayer_peer.close()
			NetworkManager.multiplayer.multiplayer_peer = peer
		finished.emit()


func exit() -> void:
	Debug.print_info("[State][Primary][Matchmaking]: << exit()")


func _on_connected_to_server() -> void:
	_connect_status = SERVER_CONNECTION_SUCCEEDED
	NetworkManager.multiplayer.connection_failed.disconnect(_on_connection_failed)


func _on_connection_failed() -> void:
	_connect_status = SERVER_CONNECTION_FAILED
	NetworkManager.multiplayer.connected_to_server.disconnect(_on_connected_to_server)

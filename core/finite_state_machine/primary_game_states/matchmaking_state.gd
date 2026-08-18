extends StateBase
class_name MatchmakingState
## Makes the NetworkManager attempts to find a peer to connect to.


# In ms
const MAX_TIME = 1500

#var _timer : int
#var _made_connection := false


func enter(_payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Primary][Matchmaking]: >> enter()")
	await NetworkManager.join_or_begin_session()
	#NetworkManager.connection_result.connect(_on_connection_result, CONNECT_ONE_SHOT)
	#NetworkManager.begin_matchmaking()
	#_timer = Time.get_ticks_msec()
	#NetworkManager.broadcast(NetworkManager.UDP_MATCHMAKING)


func update(_delta: float) -> void:
	finished.emit()
	#if _made_connection:
		#finished.emit()
	#elif Time.get_ticks_msec() - _timer > MAX_TIME:
		#Debug.print_info("[State][Primary][Matchmaking]: No connection made before timer timed out.")
		#NetworkManager.create_server()
		#finished.emit()


func exit() -> void:
	Debug.print_info("[State][Primary][Matchmaking]: << exit()")


#func handles_event(eventName: StringName) -> bool:
	#return eventName == &"other_matchmaking" \
		#or eventName == &"request_server" \
		#or eventName == &"server_created"
#
#
#func on_event(eventName: StringName, _data: Dictionary) -> void:
	#_timer += Time.get_ticks_msec()
	#match eventName:
		#&"other_matchmaking":
			#if NetworkManager.my_ip < NetworkManager.other_ip:
				#_create_server()
			#else:
				#NetworkManager.broadcast(NetworkManager.UDP_REQUEST_SERVER)
		#&"request_server":
			#_create_server()
		#&"server_created":
			#_join_other_server()


#func _create_server() -> void:
	#NetworkManager.create_server()
	#NetworkManager.broadcast(NetworkManager.UDP_SERVER_CREATED)
	#NetworkManager.multiplayer.peer_connected.connect(_on_peer_connected, CONNECT_ONE_SHOT)
#
#
#func _join_other_server() -> void:
	#NetworkManager.multiplayer.connected_to_server.connect(_on_connected_to_server, CONNECT_ONE_SHOT)
	#NetworkManager.join_other_server()


#func _on_peer_connected(peerId: int) -> void:
	#if peerId == NetworkManager.multiplayer.get_unique_id():
		#return
	#print("[State][Primary][Matchmaking]: The peer connected to my server!")
	#_made_connection = true


#func _on_connected_to_server() -> void:
	#print("[State][Primary][Matchmaking]: Conneted to peer's server!")
	#_made_connection = true


#func _on_connection_result(isMultiplayer: bool, isServer: bool) -> void:
	#print("[State][Primary][Matchmaking]: A connection result was given! isMultiplayer: %s | isServer: %s" % [str(isMultiplayer), str(isServer)])
	#finished.emit()

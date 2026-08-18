extends StateBase
class_name MatchmakingState
## Makes the NetworkManager attempts to find a peer to connect to.


enum EState {STARTING, TIMER, TIMER_JUST_FINISHED, READY, WAITING_MULTIPLAYER, DONE}



# In ms
const MAX_TIME : float = 10


var _state := EState.STARTING

var _other_can_join := false
var _other_ready := false
var _other_server_up := false
var _setup_finished := false

var _timer : float
#var _made_connection := false


func enter(_payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Primary][Matchmaking]: >> enter()")
	#await Transitioner.begin_transition()
	_timer = 0
	print("[State][Primary][Matchmaking]: enter() finished. Beginning extra timer...")
	#await GameStateManager.get_tree().create_timer(1).timeout
	#print("[State][Primary][Matchmaking]: extra wait timer finished.")
	
	
	#await NetworkManager.join_or_begin_session()
	
	#NetworkManager.connection_result.connect(_on_connection_result, CONNECT_ONE_SHOT)
	#NetworkManager.begin_matchmaking()
	#_timer = Time.get_ticks_msec()
	#NetworkManager.broadcast(NetworkManager.UDP_MATCHMAKING)


func update(delta: float) -> void:
	if _state == EState.TIMER:
		_timer += delta
		if _timer > MAX_TIME:
			_state = EState.TIMER_JUST_FINISHED
			print("[State][Primary][Matchmaking]: ...timer finished.")
			_handle_state()
	else:
		_handle_state()
	
	#finished.emit()
	
	#if _made_connection:
		#finished.emit()
	#elif Time.get_ticks_msec() - _timer > MAX_TIME:
		#Debug.print_info("[State][Primary][Matchmaking]: No connection made before timer timed out.")
		#NetworkManager.create_server()
		#finished.emit()


func exit() -> void:
	Debug.print_info("[State][Primary][Matchmaking]: << exit()")


func handles_event(eventName: StringName) -> bool:
	return GameStateManager.handles_multiplayer_events(eventName)
	#return eventName == &"other_matchmaking" \
		#or eventName == &"request_server" \
		#or eventName == &"server_created"


func on_event(eventName: StringName, _data: Dictionary) -> void:
	match eventName:
		&"started":
			_on_receive_started()
		&"no_join":
			_other_can_join = false
			# Singleplayer will get started in update()
		&"can_join":
			_on_receive_can_join()
		&"ready":
			_other_ready = true
		&"server_created":
			_other_server_up = true
			#NetworkManager.setup_session()
			NetworkManager.join_other_server()
		&"server_setup_finished":
			#_other_server_up = true
			_setup_finished = true
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


func _handle_state():
	match _state:
		EState.STARTING:
			NetworkManager.broadcast(NetworkManager.UDP_STARTED)
			_state = EState.TIMER
		EState.TIMER_JUST_FINISHED:
			if _other_can_join:
				Debug.print_info("[State][Primary][Matchmaking]: Other device [color=green]CAN JOIN[/color]! Starting multiplayer processes.")
				print("[State][Primary][Matchmaking]: Waiting for server setup to finish...")
				NetworkManager.try_create_server()
				NetworkManager.broadcast(NetworkManager.UDP_READY)
				_state = EState.WAITING_MULTIPLAYER
				#_state = EState.READY
				_handle_state()
			else:
				Debug.print_info("[State][Primary][Matchmaking]: Other device said [color=red]NO JOIN[/color]. Starting singleplayer processes.")
				NetworkManager.setup_singleplayer_session()
				_state = EState.DONE
				_handle_state()
		EState.READY:
			Debug.print_info("[State][Primary][Matchmaking]: This machine is READY. Calling NetworkManager.setup_session() and waiting...")
			#NetworkManager.setup_session()
			_state = EState.WAITING_MULTIPLAYER
			_handle_state()
		EState.WAITING_MULTIPLAYER:
			if _setup_finished:
				print("[State][Primary][Matchmaking]: ...session setup finished!")
				_state = EState.DONE
				_handle_state()
		EState.DONE:
			print("[State][Primary][Matchmaking]: Done.")
			finished.emit()


func _on_receive_started() -> void:
	_other_can_join = true
	NetworkManager.broadcast(NetworkManager.UDP_CAN_JOIN)
	# GameplayState will need to also pause current activities


func _on_receive_can_join() -> void:
	_other_can_join = true
	# My activities will need to be paused as necessary.


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

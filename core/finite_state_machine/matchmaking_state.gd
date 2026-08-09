extends StateBase
class_name MatchmakingState
## Makes the NetworkManager attempts to find a peer to connect to.


func enter(_payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Primary][Matchmaking]: >> enter()")
	NetworkManager.connection_result.connect(_on_connection_result, CONNECT_ONE_SHOT)
	NetworkManager.join_or_start_server()


#func update(_delta: float) -> void:


func exit() -> void:
	Debug.print_info("[State][Primary][Matchmaking]: << exit()")


func _on_connection_result(success: bool) -> void:
	print("[State][Primary][Matchmaking]: A connection result was given! Result: %s" % str(success))
	finished.emit()

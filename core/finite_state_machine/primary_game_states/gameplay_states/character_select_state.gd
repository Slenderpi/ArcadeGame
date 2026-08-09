extends StateBase
class_name CharacterSelectState


const CHAR_SELECT_TIME : float = 30


var selected_option : int:
	get:
		return _visuals.curr_selection
	set(value):
		_visuals.curr_selection = value


var p2_selected_option : int = 0


var _visuals : CharacterSelectScene

# -1 = down, 0 = none, 1 = up
var _last_lstick_read : int = 0
# -1 = down, 0 = none, 1 = up
var _last_rstick_read : int = 0

# In seconds
var _timer : float = CHAR_SELECT_TIME
var _timer_enabled : bool = false


func enter(_payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Gameplay][CharacterSelect]: >> enter()")
	_visuals = load("res://scenes/character_select/character_select_scene.tscn").instantiate()
	GameStateManager.folder_arcade_visuals.add_child(_visuals)
	GameStateManager.camera.first_person_target = _visuals.cam_target
	GameStateManager.camera.camera_mode = GameCamera.ECameraMode.FIRST_PERSON
	await Transitioner.end_transition()
	_timer_enabled = true


func update(_delta: float) -> void:
	_navigate_menu()
	if InputReader.is_any_binary_active():
		_visuals.on_option_chosen()
		finished.emit({&"mech0": selected_option, &"mech1": MechRefs.EMech.BIG_BLUE})
	if _timer_enabled:
		_timer = max(_timer - _delta, 0)
		if _timer == 0:
			finished.emit({&"mech0": selected_option, &"mech1": MechRefs.EMech.BIG_BLUE})


func exit() -> void:
	Debug.print_info("[State][Gameplay][CharacterSelect]: << exit()")
	await Transitioner.begin_transition()
	_visuals.queue_free()


func handles_event(eventName: StringName) -> bool:
	#return eventName == &"peer_connected"
	return eventName == &"other_matchmaking"


func on_event(eventName: StringName, _data: Dictionary) -> void:
	if eventName == &"other_matchmaking":
		_reset_timer()
		NetworkManager.broadcast(NetworkManager.UDP_SERVER_CREATED)
		NetworkManager.multiplayer.peer_connected.connect(_on_peer_connected, CONNECT_ONE_SHOT)
	#if eventName == &"peer_connected":
		#if data.multiplayer:
			#print("A challenger approaches!")
			#if data.is_host:
				#print("I will be the host")
			#else:
				#print("I will be the client")
		#else:
			#print("No challenger approaching. Singleplayer it is.")


func _navigate_menu() -> void:
	var lstick := InputReader.left_stick
	if lstick.y > 0:
		if _last_lstick_read <= 0:
			_last_lstick_read = 1
			selected_option += 1
	elif lstick.y < 0:
		if _last_lstick_read >= 0:
			_last_lstick_read = -1
			selected_option -= 1
	else:
		_last_lstick_read = 0
	var rstick := InputReader.right_stick
	if rstick.y > 0:
		if _last_rstick_read <= 0:
			_last_rstick_read = 1
			selected_option += 1
	elif rstick.y < 0:
		if _last_rstick_read >= 0:
			_last_rstick_read = -1
			selected_option -= 1
	else:
		_last_rstick_read = 0


func _reset_timer() -> void:
	_timer = CHAR_SELECT_TIME


func _on_peer_connected(peerId: int) -> void:
	if peerId == NetworkManager.multiplayer.get_unique_id():
		return
	Debug.print_info("[State][Primary][CharacterSelect]: A peer joined in the middle of character select!")

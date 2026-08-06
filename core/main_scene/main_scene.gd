extends Node
class_name MainScene
## This class is essentially a GameManager type of class that manages
## the game as a whole.
# NOTE: consider a coin_added signal, either here or in a coin-reading
#		script.


## Determines what state the game as a whole is in.
enum EMainSceneState {
	IDLE,
	BOOTING,
	ATTRACTION_MODE,
	MATCHMAKING,
	#LOGIN, # NOTE: may rename to just "MENU", or remove altogether (MATCHMAKING exists)
	SINGLEPLAYER,
	MULTIPLAYER,
	#GAMEPLAY,
	## For the MainScene that runs as the CLIENT.
	#CLIENT,
	#RESULTS
}

#region INSPECTOR EXPORTS

# TODO: maybe folders should be public instead of private?
@export_group("References")
@export_subgroup("World")
@export
var _game_camera : GameCamera
@export
var _folder_level : Node3D
@export
var _folder_characters : Node3D
@export
@warning_ignore("unused_private_class_variable")
var _folder_effects : Node3D
@export_subgroup("ArcadeVisuals")
@export
var folder_arcade_visuals : Node
@export_subgroup("UI")
@export
var _ui_manager : UiManager
@export_subgroup("Multiplayer")
@export
var level_mspawner : MultiplayerSpawner


#endregion

#region PUBLIC MEMBERS

## The current state of the program.
@export
var state : EMainSceneState:
	get:
		return _state
	set(value):
		_state = value
		_on_state_changed()
var _state : EMainSceneState = EMainSceneState.BOOTING
## The current [GameMode] in use.
var game_mode : GameMode = null

## The currently spawned [StageData]
var active_stage : StageData
### The currently spawned [MechCharacter] for Player 0
#var active_mech_0 : MechCharacter
### The currently spawned [MechCharacter] for Player 1
#var active_mech_1 : MechCharacter

#endregion

#region NODE OVERRIDES

func _ready() -> void:
	GameStateManager.folder_arcade_visuals = folder_arcade_visuals
	GameStateManager.start()
	#NetworkManager.versus_peer_found.connect(_on_versus_peer_found)
	#NetworkManager.server_started.connect(_on_server_started)
	#NetworkManager.disconnected.connect(_on_disconnected)
	#_ui_manager._main_scene = self
	#state = EMainSceneState.BOOTING


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"insert_coin"):
		# TODO: TEMP, should be done in a coin manager
		print_rich("[color=orange][MainScene]: COIN KEY PRESSED. COIN INSERT SIMULATED.")
		if state == EMainSceneState.ATTRACTION_MODE:
			Debug.print_success("[MainScene]: Matchmaking triggered.")
			state = EMainSceneState.MATCHMAKING


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed():
			if event.keycode == KEY_ESCAPE:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

#endregion

#region STATES

func _on_state_changed() -> void:
	match _state:
		EMainSceneState.IDLE:
			Debug.print_info("[MainScene]: state -> IDLE.")
		EMainSceneState.BOOTING:
			_on_state_booting()
		EMainSceneState.ATTRACTION_MODE:
			_on_state_attraction_mode()
		EMainSceneState.MATCHMAKING:
			_on_state_matchmaking()
		EMainSceneState.SINGLEPLAYER:
			_on_state_singleplayer()
		EMainSceneState.MULTIPLAYER:
			_on_state_multiplayer()
		#EMainSceneState.LOGIN:
			#_on_state_login()
		#EMainSceneState.GAMEPLAY:
			#_on_state_gameplay()
		#EMainSceneState.CLIENT:
			#_on_state_client()
		#EMainSceneState.RESULTS:
			#pass
	#_ui_manager.on_main_scene_state_changed()


func _on_state_booting() -> void:
	Debug.print_info("[MainScene]: state -> BOOTING.")
	print("[MainScene]: Booting not yet implemented. Going straight to ATTRACTION_MODE.")
	state = EMainSceneState.ATTRACTION_MODE


func _on_state_attraction_mode() -> void:
	Debug.print_info("[MainScene]: state -> ATTRACTION_MODE.")
	NetworkManager.can_versus = false
	_ui_manager.show_attraction_mode()
	#_ui_manager.on_main_scene_state_changed()
	# TODO: On any controller input, enter training game mode
	#print("Attraction not yet implemented. Going straight to LOGIN.")
	#state = EMainSceneState.LOGIN


func _on_state_matchmaking() -> void:
	Debug.print_info("[MainScene]: state -> MATCHMAKING.")
	print("[MainScene]: Awaiting NetworkManager to find a peer...")
	_ui_manager.show_matchmaking()
	NetworkManager.can_versus = true
	var peerIp : String = await NetworkManager.find_peer()
	
	var foundPeer := !peerIp.is_empty()
	_ui_manager.on_matchmaking_result(foundPeer)
	await get_tree().create_timer(1.0).timeout
	
	if foundPeer:
		Debug.print_info("[MainScene]: Matchmaking result: NetworkManager found a peer! Peer ip: %s" % peerIp)
		var serverIp : String = _choose_host_ip(peerIp)
		print("[MainScene]: The IP that will be the server is: %s" % serverIp)
		NetworkManager.start_server(serverIp)
	else:
		Debug.print_info("[MainScene]: Matchmaking result: NetworkManager did not find an available peer. Entering Singleplayer mode!")
		NetworkManager.start_singleplayer_server()


func _on_state_singleplayer() -> void:
	Debug.print_info("[MainScene]: state -> SINGLEPLAYER.")
	NetworkManager.can_versus = true
	game_mode = SingleplayerGameMode.new(self)
	game_mode.start()
	_ui_manager.show_gameplay()


func _on_state_multiplayer() -> void:
	Debug.print_info("[MainScene]: state -> MULTIPLAYER.")
	NetworkManager.can_versus = false
	if not multiplayer.is_server():
		return
	game_mode = MultiplayerGameMode.new(self)
	game_mode.start()
	_ui_manager.show_gameplay()


#func _on_state_login() -> void:
	#Debug.print_info("[MainScene]: state -> LOGIN.")
	## TODO: use NetworkManager to determine if the other machine is ready to play.
	## 		If fails, SingleplayerGameMode
	##		If succeeds, MultiplayerGameMode
	#print("[MainScene]: Defaulting to MultiplayerGameMode.")
	#game_mode = MultiplayerGameMode.new(self)
	#print("[MainScene]: Begin the server to enter GAMEPLAY.")
	##print("Login not yet implemented. Going straight to GAMEPLAY.")
	##state = EMainSceneState.GAMEPLAY


#func _on_state_gameplay() -> void:
	#Debug.print_info("[MainScene]: state -> GAMEPLAY.")
	#game_mode = MultiplayerGameMode.new(self)
	#assert(game_mode != null, "MainScene entered GAMEPLAY but game_mode is null. Should be set in LOGIN state.")
	#if not multiplayer.is_server():
		#return
	#game_mode.start()


#func _on_state_client() -> void:
	#Debug.print_info("[MainScene]: state -> CLIENT.")

#endregion

#region PUBLIC METHODS

## Spawns a stage.
## Should only be called by the host.
func spawn_stage(levelResource: Resource) -> void:
	print("[MainScene]: Spawning level")
	var stage := levelResource.instantiate() as Node3D
	active_stage = stage as StageData
	_folder_level.add_child(stage)


## Spawns MechCharacters for both Players. Player0 is ALWAYS the host's Player,
## so their peerId will always be 0.
## [br]
## [b]This function is server locked.[/b]
func spawn_mechs(mechType0: MechRefs.EMech, controllerType0: int, mechType1: MechRefs.EMech, controllerType1: int) -> void:
	if not multiplayer.is_server():
		return
	print("[MainScene]: Spawning mechs. My peerId: ", multiplayer.get_unique_id(), " | Other: ", NetworkManager.other_peer_id)
	_spawn_mech.rpc(mechType0, 1, controllerType0, active_stage.spawn_point_0.transform)
	_spawn_mech.rpc(mechType1, NetworkManager.other_peer_id, controllerType1, active_stage.spawn_point_1.transform)


## Resets the entire game world and the MainScene's per-game internal values.
## Also resets camera and _dev_canvas.
func reset() -> void:
	Debug.print_info("[MainScene]: reset() called. Resetting World folders and MainScene's internal values.")
	for c in _folder_characters.get_children():
		c.queue_free()
	for c in _folder_level.get_children():
		c.queue_free()
	active_stage = null
	#active_mech_0 = null
	#active_mech_1 = null
	game_mode = null
	_game_camera.camera_mode = GameCamera.ECameraMode.NONE
	_game_camera.first_person_target = null

#endregion

#region MISC PRIVATE METHODS

@rpc("any_peer", "call_local")
func _spawn_mech(mechType: MechRefs.EMech, peerId: int, controllerType: int, transform: Transform3D) -> void:
	var mech := MechRefs.instantiate_mech(mechType)
	mech.name = str(peerId)
	mech.controller_type = controllerType
	mech.transform = transform
	_folder_characters.add_child(mech, true)
	_on_mech_character_instantiated(mech)


func _on_mech_character_instantiated(mechChar: MechCharacter) -> void:
	if not mechChar.is_multiplayer_authority() or mechChar.name == "0":
		print("[MainScene]: MechCharacter %s is not my character" % mechChar.name)
		return
	print("[MainScene]: MechCharacter %s IS my character, setting camera and related stuff to it." % mechChar.name)
	_game_camera.first_person_target = mechChar
	_game_camera.camera_mode = GameCamera.ECameraMode.FIRST_PERSON
	# TODO TEMP: The below code may be better done via an event
	_ui_manager.on_mech_spawned(mechChar)


# Chooses the IP to become the host. Priority:
# Not IPv6
# Smaller IPv4 numeric value (i.e. 1.1.1.1 becomes 1111)
# String-based comparison of IPv6: my_ip if my_ip < peerIp else peerIp
func _choose_host_ip(peerIp: String) -> String:
	var myIp4Parts := NetworkManager.my_ip.split('.')
	var peerIp4Parts := peerIp.split('.')
	if myIp4Parts.size() != 4:
		if peerIp4Parts.size() != 4:
			# IPv6 vs IPv6
			return NetworkManager.my_ip if NetworkManager.my_ip < peerIp else peerIp
		else:
			# Only peer is IPv4
			return peerIp
	elif peerIp4Parts.size() != 4:
		# Only my IP is IPv4
		return NetworkManager.my_ip
	else:
		# IPv4 vs IPv4
		var myNumeric := 0
		var peerNumeric := 0
		for i in range(0, 4):
			for c in myIp4Parts[i]:
				myNumeric = myNumeric * 10 + c.to_int()
			for c in peerIp4Parts[i]:
				peerNumeric = peerNumeric * 10 + c.to_int()
		return NetworkManager.my_ip if myNumeric < peerNumeric else peerIp

#endregion

#region NETMAN SIGNAL CONNECTIONS

func _on_versus_peer_found() -> void:
	print("[MainScene]: Versus peer found. Current game should get paused and UI'd.")
	reset()
	_ui_manager.on_versus_found()
	state = EMainSceneState.IDLE


func _on_server_started(isMultiplayer: bool):
	Debug.print_success("[MainScene]: Server started! Gameplay can begin.")
	reset()
	multiplayer.multiplayer_peer = NetworkManager.multiplayer.multiplayer_peer
	if isMultiplayer:
		state = EMainSceneState.MULTIPLAYER
	else:
		state = EMainSceneState.SINGLEPLAYER


func _on_disconnected():
	print_rich("[color=orange][MainScene]: Peers have disconnected. Multiplayer should end.")
	# TODO
	reset()
	NetworkManager.close_server()
	state = EMainSceneState.ATTRACTION_MODE

#endregion

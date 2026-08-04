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
	LOGIN, # NOTE: may rename to just "MENU"
	SINGLEPLAYER,
	MULTIPLAYER,
	GAMEPLAY,
	## For the MainScene that runs as the CLIENT.
	CLIENT,
	RESULTS
}


#@export
#var player_controller : PackedScene
#var player_client_scene := preload("res://entities/player_client/player_client.tscn")

#@export_category("Developer Config")
### If true, skips visuals related to booting (the booting process itself still completes).
#@export
#var _skip_booting : bool = false

@export_group("References")
@export_subgroup("World")
@export
@warning_ignore("unused_private_class_variable")
var _game_camera : GameCamera
@export
var _folder_level : Node3D
@export
var _folder_entities : Node3D
@export
@warning_ignore("unused_private_class_variable")
var _folder_effects : Node3D
@export_subgroup("UI")
@export
@warning_ignore("unused_private_class_variable")
var _folder_ui : Node
@export_subgroup("Multiplayer")
@export
var level_mspawner : MultiplayerSpawner
@export
var entities_mspawner : MultiplayerSpawner
@export
var _dev_canvas : DevCanvas


## The current state of the program.
@export
var state : EMainSceneState:
	get:
		return _state
	set(value):
		_state = value
		match _state:
			EMainSceneState.IDLE:
				Debug.print_info("MainScene state: IDLE.")
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
			EMainSceneState.LOGIN:
				_on_state_login()
			EMainSceneState.GAMEPLAY:
				_on_state_gameplay()
			EMainSceneState.CLIENT:
				_on_state_client()
			EMainSceneState.RESULTS:
				pass
var _state : EMainSceneState = EMainSceneState.BOOTING
## The current [GameMode] in use.
var game_mode : GameMode = null

## The currently spawned [StageData]
var active_stage : LevelData
## The currently spawned [MechCharacter] for Player 0
var active_mech_0 : MechCharacter
## The currently spawned [MechCharacter] for Player 1
var active_mech_1 : MechCharacter


func _ready() -> void:
	entities_mspawner.spawned.connect(_on_multiplayer_entity_spawned)
	#entities_mspawner.spawn_function = func(data: Variant) -> Node:
		#var mech := mech_to_load_0.instantiate() as MechCharacter
		#mech.name = str(data["peer_id"])
		#mech.global_transform = data["transform"]
		#mech.controller_type = data["controller"]
		#return mech
	#
	
	NetworkManager.versus_peer_found.connect(func(peerIp: String):
		print("Versus peer found (%s). Current game should get paused and UI'd." % peerIp)
		reset()
		state = EMainSceneState.IDLE
	)
	NetworkManager.server_started.connect(func(isMultiplayer: bool):
		print_rich("[color=green]Server started! Gameplay can begin.")
		reset()
		multiplayer.multiplayer_peer = NetworkManager.multiplayer.multiplayer_peer
		if isMultiplayer:
			NetworkManager.can_versus = false
			state = EMainSceneState.MULTIPLAYER
		else:
			NetworkManager.can_versus = true
			state = EMainSceneState.SINGLEPLAYER
	)
	NetworkManager.disconnected.connect(func():
		print_rich("[color=orange]Peers have disconnected. Multiplayer should end.")
		# TODO
		reset()
		state = EMainSceneState.ATTRACTION_MODE
	)
	#NetworkManager.found_peer.connect(func():
		#Debug.print_info("Found peer")
		#if not multiplayer.is_server():
			#state = EMainSceneState.CLIENT
	#)
	NetworkManager.player_connected.connect(func(peerId: int):
		Debug.print_info("Player joined: %d" % peerId)
		#if multiplayer.is_server():
			#if peerId != 1:
				#print("Setting main scene state to GAMEPLAY.")
				#state = EMainSceneState.GAMEPLAY
		#else:
			#if peerId == 1:
				#print("Setting main scene state to CLIENT.")
				#state = EMainSceneState.CLIENT
	)
	NetworkManager.player_disconnected.connect(func(peerId: int):
		Debug.print_info("Player left: %d. Calling reset()." % peerId)
		reset()
	)
	
	state = EMainSceneState.BOOTING


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"insert_coin"):
		# TODO: TEMP, should be done in a coin manager
		print("COIN KEY PRESSED. COIN INSERT SIMULATED.")
		if state == EMainSceneState.ATTRACTION_MODE:
			print("Matchmaking triggered.")
			state = EMainSceneState.MATCHMAKING


func _on_state_booting() -> void:
	Debug.print_info("MainScene state: BOOTING.")
	print("Booting not yet implemented. Going straight to ATTRACTION_MODE.")
	state = EMainSceneState.ATTRACTION_MODE


func _on_state_attraction_mode() -> void:
	Debug.print_info("MainScene state: ATTRACTION_MODE.")
	# TODO: On any controller input, enter 
	#print("Attraction not yet implemented. Going straight to LOGIN.")
	#state = EMainSceneState.LOGIN


func _on_state_matchmaking() -> void:
	Debug.print_info("MainScene state: MATCHMAKING.")
	print("Asking NetworkManager to find a peer...")
	NetworkManager.can_versus = true
	var peerIp : String = await NetworkManager.find_peer()
	if peerIp.is_empty():
		Debug.print_info("Matchmaking result: NetworkManager did not find an available peer. Entering Singleplayer mode!")
		NetworkManager.start_singleplayer_server()
	else:
		Debug.print_info("Matchmaking result: NetworkManager found a peer! Peer ip: %s" % peerIp)
		var serverIp : String = _choose_host_ip(peerIp)
		print("The IP that will be the server is: %s" % serverIp)
		NetworkManager.start_server(serverIp)


func _on_state_singleplayer() -> void:
	Debug.print_info("MainScene state: SINGLEPLAYER.")
	game_mode = SingleplayerGameMode.new(self)
	game_mode.start()


func _on_state_multiplayer() -> void:
	Debug.print_info("MainScene state: MULTIPLAYER.")
	if not multiplayer.is_server():
		return
	game_mode = MultiplayerGameMode.new(self)
	game_mode.start()


func _on_state_login() -> void:
	Debug.print_info("MainScene state: LOGIN.")
	# TODO: use NetworkManager to determine if the other machine is ready to play.
	# 		If fails, SingleplayerGameMode
	#		If succeeds, MultiplayerGameMode
	print("Defaulting to MultiplayerGameMode.")
	game_mode = MultiplayerGameMode.new(self)
	print("Begin the server to enter GAMEPLAY.")
	#print("Login not yet implemented. Going straight to GAMEPLAY.")
	#state = EMainSceneState.GAMEPLAY


func _on_state_gameplay() -> void:
	Debug.print_info("MainScene state: GAMEPLAY.")
	game_mode = MultiplayerGameMode.new(self)
	assert(game_mode != null, "MainScene entered GAMEPLAY but game_mode is null. Should be set in LOGIN state.")
	if not multiplayer.is_server():
		return
	game_mode.start()


func _on_state_client() -> void:
	Debug.print_info("MainScene state: CLIENT.")


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


## Spawns the level.
## Should only be called by the host.
func spawn_level(levelResource: Resource) -> void:
	print("Spawning level")
	var stage := levelResource.instantiate() as Node3D
	active_stage = stage as LevelData
	_folder_level.add_child(stage)


#@rpc("any_peer", "call_local")
#func _spawn_mech_0(mechScene: PackedScene) -> void:
	#print("Spawning mech0!")
	#active_mech_0 = mechScene.instantiate() as MechCharacter
	#active_mech_0.name = "1"
	#active_mech_0.transform = active_stage.spawn_point_0.transform
	#_folder_entities.add_child(active_mech_0, true)


@rpc("any_peer", "call_local")
func _spawn_mech(mechScene: PackedScene, peerId: int, controllerType: int, transform: Transform3D) -> void:
	var mech := mechScene.instantiate() as MechCharacter
	mech.name = str(peerId)
	mech.controller_type = controllerType
	mech.transform = transform
	_folder_entities.add_child(mech, true)
	_on_mech_character_spawned_general(mech)


## Spawns MechCharacters for both Players. Player0 is ALWAYS the host's Player,
## so their peerId will always be 0.
## [br]
## [b]This function is server locked.[/b]
func spawn_mech(mechScene0: PackedScene, controllerType0: int, mechScene1: PackedScene, controllerType1: int) -> void:
	if not multiplayer.is_server():
		return
	print("---- Spawning mechs ----")
	
	_spawn_mech.rpc(mechScene0, 1, controllerType0, active_stage.spawn_point_0.transform)
	_spawn_mech.rpc(mechScene1, NetworkManager.other_peer_id, controllerType1, active_stage.spawn_point_1.transform)
	
	#var mech0 = mechScene0.instantiate() as MechCharacter
	#mech0.name = "1"
	#mech0.peer_id = 1
	#mech0.transform = active_stage.spawn_point_0.global_transform
	#mech0.controller_type = controllerType0
	#
	#var mech1 = mechScene1.instantiate() as MechCharacter
	#mech1.name = str(NetworkManager.other_peer_id)
	#mech1.peer_id = NetworkManager.other_peer_id
	#mech1.transform = active_stage.spawn_point_1.global_transform
	#mech1.controller_type = controllerType1
	#
	#_folder_entities.add_child(mech0, true)
	#_folder_entities.add_child(mech1, true)
	#
	## Call this function explicitly for the server.
	## The spawned signal on the MultiplayerSpawner only calls it on the client.
	#_on_multiplayer_entity_spawned(mech0)
	#_on_multiplayer_entity_spawned(mech1)


func _on_multiplayer_entity_spawned(node: Node):
	if node is MechCharacter:
		print("Mech spawned! peerId of mech: ", node.peer_id)
		if node.peer_id == 1:
			print("active_mech_0 set")
			active_mech_0 = node
		else:
			print("active_mech_1 set")
			active_mech_1 = node
		if node.peer_id == multiplayer.get_unique_id():
			print("This is my entity. Calling general func.")
			set_multiplayer_authority(node.peer_id)
			_on_mech_character_spawned_general(node)


func _on_mech_character_spawned_general(mechChar: MechCharacter) -> void:
	if not mechChar.is_multiplayer_authority() or mechChar.name == "0":
		print("MechCharacter %s is not my character" % mechChar.name)
		return
	print("MechCharacter %s IS my character, setting camera and related stuff to it." % mechChar.name)
	_dev_canvas.mech_character = mechChar
	_game_camera.first_person_target = mechChar
	_game_camera.camera_mode = GameCamera.ECameraMode.FIRST_PERSON


func reset() -> void:
	Debug.print_info("reset() called. Resetting World folders and MainScene's internal values.")
	for c in _folder_entities.get_children():
		c.queue_free()
	for c in _folder_level.get_children():
		c.queue_free()
	active_stage = null
	active_mech_0 = null
	active_mech_1 = null
	game_mode = null


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed():
			if event.keycode == KEY_ESCAPE:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

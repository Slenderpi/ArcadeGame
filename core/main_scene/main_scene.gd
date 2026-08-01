extends Node
class_name MainScene
## This class is essentially a GameManager type of class that manages
## the game as a whole.
# NOTE: consider a coin_added signal, either here or in a coin-reading
#		script.


## Determines what state the game as a whole is in.
enum EMainSceneState {
	BOOTING,
	ATTRACTION_MODE,
	LOGIN, # NOTE: may rename to just "MENU"
	GAMEPLAY,
	RESULTS
}


@export
var level_to_load : PackedScene

@export
var mech_to_load_0 : PackedScene
@export
var mech_to_load_1 : PackedScene
#@export
#var player_controller : PackedScene
var player_client_scene := preload("res://entities/player_client/player_client.tscn")

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
var state : EMainSceneState:
	get:
		return _state
	set(value):
		_state = value
		match state:
			EMainSceneState.BOOTING:
				_on_state_booting()
			EMainSceneState.ATTRACTION_MODE:
				_on_state_attraction_mode()
			EMainSceneState.LOGIN:
				_on_state_login()
			EMainSceneState.GAMEPLAY:
				_on_state_gameplay()
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
	#entities_mspawner.spawned.connect(_on_mech_character_spawned)
	#entities_mspawner.spawn_function = func(data: Variant) -> Node:
		#var mech := mech_to_load_0.instantiate() as MechCharacter
		#mech.name = str(data["peer_id"])
		#mech.global_transform = data["transform"]
		#mech.controller_type = data["controller"]
		#return mech
	#
	NetworkManager.found_peer.connect(func():
		Debug.print_info("Found peer")
	)
	NetworkManager.player_connected.connect(func(peerId: int):
		Debug.print_info("Player joined: %d" % peerId)
		if not multiplayer.is_server():
			return
		if peerId != 1:
			print("Setting main scene state to GAMEPLAY.")
			state = EMainSceneState.GAMEPLAY
	)
	NetworkManager.player_disconnected.connect(func(peerId: int):
		Debug.print_info("Player left: %d" % peerId)
		if not multiplayer.is_server():
			return
		Debug.print_info("Clearing folders.")
		for c in _folder_level.get_children():
			c.queue_free()
		for c in _folder_entities.get_children():
			c.queue_free()
	)
	
	state = EMainSceneState.BOOTING
	
	#_spawn_mech_character_for_player(mech_to_load_0, 0)
	#_spawn_mech_character_for_player(mech_to_load_1, 1)
	
	#_game_camera.first_person_target = spawned_mechs[0]
	#_game_camera.camera_mode = GameCamera.ECameraMode.FIRST_PERSON
	
	#_dev_canvas.mech_character = spawned_mechs[0]


func _on_state_booting() -> void:
	Debug.print_info("MainScene state: BOOTING.")
	print("Booting not yet implemented. Going straight to ATTRACTION_MODE.")
	state = EMainSceneState.ATTRACTION_MODE


func _on_state_attraction_mode() -> void:
	Debug.print_info("MainScene state: ATTRACTION_MODE.")
	# TODO: On any controller input, enter 
	print("Attraction not yet implemented. Going straight to LOGIN.")
	state = EMainSceneState.LOGIN


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
	assert(game_mode != null, "MainScene entered GAMEPLAY but game_mode is null. Should be set in LOGIN state.")
	if not multiplayer.is_server():
		return
	game_mode.start()


## Spawns the level.
## Should only be called by the host.
func spawn_level(levelResource: Resource) -> void:
	print("Spawning level")
	var stage := levelResource.instantiate() as Node3D
	active_stage = stage as LevelData
	_folder_level.add_child(stage)


#func _spawn_level_and_characters() -> void:
	#if not multiplayer.is_server():
		#return
	#
	#var stage := level_to_load.instantiate() as Node3D
	#active_stage = stage as LevelData
	#_folder_level.add_child(stage)
	#
	#_on_mech_character_spawned(_spawn_mech_character(1, active_stage.spawn_point_0.global_transform, 1))
	#_spawn_mech_character(multiplayer.get_peers()[0], active_stage.spawn_point_1.global_transform, 1)


## Spawns MechCharacters for both Players. Player0 is ALWAYS the host's Player,
## so their peerId will always be 0.
## [br]
## [b]This function is server locked.[/b]
func spawn_mech(mechScene0: PackedScene, controllerType0: int, mechScene1: PackedScene, peerId1: int, controllerType1: int) -> void:
	if not multiplayer.is_server():
		return
	
	active_mech_0 = mechScene0.instantiate() as MechCharacter
	active_mech_0.peer_id = 1
	active_mech_0.transform = active_stage.spawn_point_0.global_transform
	active_mech_0.controller_type = controllerType0
	_folder_entities.add_child(active_mech_0, true)
	
	active_mech_1 = mechScene1.instantiate() as MechCharacter
	active_mech_1.peer_id = peerId1
	active_mech_1.transform = active_stage.spawn_point_1.global_transform
	active_mech_1.controller_type = controllerType1
	_folder_entities.add_child(active_mech_1, true)
	
	_on_mech_character_0_spawned()
	_on_mech_character_1_spawned.rpc()


#func _spawn_mech_character(peerId: int, transform: Transform3D, controller: int) -> Node:
	#return entities_mspawner.spawn({
		#"peer_id" = peerId,
		#"transform" = transform,
		#"controller" = controller
	#})


# Since this function is for Player0, it should only be called by the server.
# This check is not explicitly validated.
func _on_mech_character_0_spawned() -> void:
	print("Mech 0 spawned. Has authority: ", active_mech_0.is_multiplayer_authority())
	_on_mech_character_spawned_general(active_mech_0)


# Since this function is for Player1, only the client should actually run this.
@rpc("any_peer")
func _on_mech_character_1_spawned() -> void:
	print("Mech 1 spawned. Has authority: ", active_mech_1.is_multiplayer_authority())
	_on_mech_character_spawned_general(active_mech_1)


func _on_mech_character_spawned_general(mechChar: MechCharacter) -> void:
	_dev_canvas.mech_character = mechChar
	_game_camera.first_person_target = mechChar
	_game_camera.camera_mode = GameCamera.ECameraMode.FIRST_PERSON


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed():
			if event.keycode == KEY_ESCAPE:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

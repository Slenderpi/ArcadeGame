extends Node


## If true, will skip from BootingState to GameplayState/CombatState
const DEV_SKIP_TO_COMBAT : bool = false
## If SKIP_TO_COMBAT is true, this stage will be the one that gets spawned.
const DEV_SKIP_STAGE : StageRefs.EStage = StageRefs.EStage.DEV
## If SKIP_TO_COMBAT is true, this stage will be the mech that's spawned for Player0.
const DEV_SKIP_MECH_0 : MechRefs.EMech = MechRefs.EMech.MECH_GUY
## If SKIP_TO_COMBAT is true, this stage will be the mech that's spawned for Player1.
const DEV_SKIP_MECH_1 : MechRefs.EMech = MechRefs.EMech.BIG_BLUE


#region PUBLIC MEMBERS

## The state machine that manages the game as a whole.[br][br]
## There are three primary states:[br]
## 1. [BootingState][br]
## 2. [AttractModeState][br]
## 3. [GameplayState]
var fsm : StateMachine
## Reference to the GameCamera.
## The MainScene should contain it when calling [method GameStateManager.start].
var camera : GameCamera

#var is_player1 := true

var folder_arcade_visuals : Node

#endregion

var _reset_for_opponent := false


#region NODE OVERRIDES

func _ready() -> void:
	NetworkManager.opponent_found.connect(func():
		_reset_for_opponent = true
		fsm.push_event(&"opponent_found")
	)
	NetworkManager.opponent_connected.connect(func():
		_reset_for_opponent = true
		fsm.push_event(&"opponent_connected")
	)
	
	#NetworkManager.connection_established.connect(_on_connection_established)
	#NetworkManager.connection_lost.connect(_on_connection_lost)
	
	#NetworkManager.received_message.connect(func(msg: Array[String]):
		#if msg[0] == NetworkManager.UDP_STARTED:
			#fsm.push_event(&"started")
		#elif msg[0] == NetworkManager.UDP_NO_JOIN:
			#fsm.push_event(&"no_join")
		#elif msg[0] == NetworkManager.UDP_CAN_JOIN:
			#fsm.push_event(&"can_join")
		#elif msg[0] == NetworkManager.UDP_READY:
			#fsm.push_event(&"ready")
		#elif msg[0] == NetworkManager.UDP_SERVER_CREATED:
			#fsm.push_event(&"server_created")
	#)
	#NetworkManager.server_setup_finished.connect(func():
		#fsm.push_event(&"server_setup_finished")
	#)
	
	process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	fsm.update(delta)

#endregion

#region PUBLIC METHODS

## Starts the state machine.
## Should be called by [method MainScene._ready].[br][br]
## The state machine will start in the [BootingState].
func start(mainScene: MainScene) -> void:
	Debug.print_notify("[GameStateManager]: Game state starting.")
	folder_arcade_visuals = mainScene.folder_arcade_visuals
	camera = mainScene._game_camera
	process_mode = Node.PROCESS_MODE_ALWAYS
	fsm = StateMachine.new()
	add_child(fsm)
	_enter_state_booting(mainScene)


## Can be used by other states to claim they handle events related to multiplayer setup.
func handles_multiplayer_events(eventName: StringName) -> bool:
	return eventName == &"started" \
		|| eventName == &"can_join" \
		|| eventName == &"ready" \
		|| eventName == &"server_created" \
		|| eventName == &"server_setup_finished" \
		|| eventName == &"no_join"

#endregion

#region STATE PROCESSES

func _enter_state_booting(mainScene: MainScene) -> void:
	fsm.change_state(StateFactory.create(BootingState, _enter_state_attract_mode), {&"main_scene": mainScene})


func _enter_state_attract_mode() -> void:
	if DEV_SKIP_TO_COMBAT:
		_enter_state_gameplay()
	else:
		fsm.change_state(StateFactory.create(AttractModeState, _enter_state_matchmaking))


func _enter_state_matchmaking() -> void:
	fsm.change_state(StateFactory.create(MatchmakingState, _enter_state_gameplay))


func _enter_state_gameplay() -> void:
	if _reset_for_opponent:
		_enter_state_gameplay()
	else:
		fsm.change_state(StateFactory.create(GameplayState, _enter_state_attract_mode))

#endregion


func _on_connection_established(is_multiplayer: bool, is_host: bool) -> void:
	fsm.push_event(&"peer_connected", {"multiplayer": is_multiplayer, "is_host": is_host})


func _on_connection_lost() -> void:
	fsm.push_event(&"peer_disconnected", {})

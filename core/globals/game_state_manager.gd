extends Node


#region PUBLIC MEMBERS

## The state machine that manages the game as a whole.[br][br]
## There are three primary states:[br]
## 1. BootingState[br]
## 2. AttractModeState[br]
## 3. GameplayState
var fsm : StateMachine

var folder_arcade_visuals : Node

#endregion


#region NODE OVERRIDES

func _ready() -> void:
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
	process_mode = Node.PROCESS_MODE_ALWAYS
	fsm  = StateMachine.new()
	_enter_state_booting(mainScene)

#endregion

#region STATE PROCESSES

func _enter_state_booting(mainScene: MainScene) -> void:
	fsm.change_state(StateFactory.create(BootingState, _enter_state_attract_mode), {"main_scene": mainScene})


func _enter_state_attract_mode() -> void:
	fsm.change_state(StateFactory.create(AttractModeState, _enter_state_gameplay))


func _enter_state_gameplay() -> void:
	fsm.change_state(StateFactory.create(GameplayState, _enter_state_attract_mode))

#endregion

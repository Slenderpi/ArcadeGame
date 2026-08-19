extends StateBase
class_name CombatState


# TODO: Put in some config file
const ROUND_DURATION : float = 5


var _spawned_stage : StageData
var _mech_0 : MechCharacter
var _mech_1 : MechCharacter

var _timer : float


func enter(payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Gameplay][Combat]: >> enter()")
	_timer = ROUND_DURATION
	# TODO TEMP
	_spawned_stage = StageRefs.instantiate_stage(StageRefs.EStage.DEV)
	GameStateManager.folder_arcade_visuals.add_child(_spawned_stage)
	
	_mech_0 = MechRefs.instantiate_mech(payload[&"mech0"])
	_mech_0.controller_type = 1
	_mech_0.name = "1"
	_mech_0.transform = _spawned_stage.spawn_point_0.transform
	
	_mech_1 = MechRefs.instantiate_mech(payload[&"mech1"])
	_mech_1.controller_type = 0
	_mech_1.name = "0"
	_mech_1.transform = _spawned_stage.spawn_point_1.transform
	
	GameStateManager.folder_arcade_visuals.add_child(_mech_0, true)
	GameStateManager.folder_arcade_visuals.add_child(_mech_1, true)
	
	GameStateManager.camera.camera_target = _mech_0
	
	await Transitioner.end_transition()


func update(delta: float) -> void:
	# TODO
	_timer = max(0, _timer - delta)
	if _timer <= 0:
		finished.emit({&"winner": &"player0"})


func exit() -> void:
	Debug.print_info("[State][Gameplay][Combat]: >> exit()")
	_spawned_stage.queue_free()
	_mech_0.queue_free()

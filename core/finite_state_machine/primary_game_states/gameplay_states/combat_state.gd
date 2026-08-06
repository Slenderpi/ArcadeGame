extends StateBase
class_name CombatState


var _spawned_stage : StageData
var _mech_0 : MechCharacter


func enter(_payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Gameplay][Combat]: >> enter()")
	# TODO TEMP
	_spawned_stage = StageRefs.instantiate_stage(StageRefs.EStage.DEV)
	GameStateManager.folder_arcade_visuals.add_child(_spawned_stage)
	_mech_0 = MechRefs.instantiate_mech(MechRefs.EMech.MECH_GUY)
	_mech_0.controller_type = 1
	_mech_0.name = "1"
	GameStateManager.folder_arcade_visuals.add_child(_mech_0, true)
	await Transitioner.end_transition()


func update(_delta: float) -> void:
	# TODO
	finished.emit({&"winner": &"player0"})


func exit() -> void:
	Debug.print_info("[State][Gameplay][Combat]: >> exit()")
	_spawned_stage.queue_free()
	_mech_0.queue_free()

extends StateBase
class_name GameplayState


var fsm : StateMachine


func enter(_payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Primary][Gameplay]: >> enter()")
	Transitioner.end_transition()
	# TODO
	# TODO TEMP
	GameStateManager.folder_arcade_visuals.add_child(StageRefs.instantiate_stage(StageRefs.EStage.DEV))
	var mech := MechRefs.instantiate_mech(MechRefs.EMech.MECH_GUY)
	mech.controller_type = 1
	mech.name = "1"
	GameStateManager.folder_arcade_visuals.add_child(mech, true)

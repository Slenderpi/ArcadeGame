extends StateBase
class_name StageSelectState


var _ret_payload : Dictionary


func enter(payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Gameplay][StageSelect]: >> enter()")
	_ret_payload = payload
	await Transitioner.end_transition()


func update(_delta: float) -> void:
	# TODO: Stage selection
	_ret_payload[&"stage"] = StageRefs.EStage.DEV
	#finished.emit(_ret_payload)
	fsm_owner.change_state(StateIds.COMBAT, _ret_payload)


func exit() -> void:
	Debug.print_info("[State][Gameplay][StageSelect]: << exit()")
	await Transitioner.begin_transition()

extends StateBase
class_name GameplayState


## If true, skips StageSelectState.
const DEV_SKIP_STAGE_SELECT_STATE = true


var fsm : StateMachine


func enter(_payload: Dictionary = {}) -> void:
	Debug.print_info("[State][Primary][Gameplay]: >> enter()")
	fsm = StateMachine.new()
	if GameStateManager.DEV_SKIP_TO_COMBAT:
		_enter_state_combat({
			&"mech0": GameStateManager.DEV_SKIP_MECH_0,
			&"mech1": GameStateManager.DEV_SKIP_MECH_1,
			&"stage": GameStateManager.DEV_SKIP_STAGE
		})
	else:
		_enter_state_character_select()
	await Transitioner.end_transition()


func update(delay: float) -> void:
	fsm.update(delay)


func exit() -> void:
	Debug.print_info("[State][Primary][Gameplay]: << exit()")


#region STATE PROCESSES

func _enter_state_character_select() -> void:
	fsm.change_state(StateFactory.create(CharacterSelectState, _enter_state_stage_select))


# TODO
# payload idea: character choices
func _enter_state_stage_select(payload: Dictionary) -> void:
	print("[State][Primary][Gameplay]: _enter_state_stage_select() given payload %s." % str(payload))
	if DEV_SKIP_STAGE_SELECT_STATE:
		payload[&"stage"] = StageRefs.EStage.DEV
		_enter_state_combat(payload)
	else:
		fsm.change_state(StateFactory.create(StageSelectState, _enter_state_combat), payload)


# TODO
# payload idea: character choices, stage choices
func _enter_state_combat(payload: Dictionary) -> void:
	print("[State][Primary][Gameplay]: _enter_state_combat() given payload %s." % str(payload))
	fsm.change_state(StateFactory.create(CombatState, _enter_state_results), payload)


# TODO
# payload idea: combat results
func _enter_state_results(payload: Dictionary) -> void:
	print("[State][Primary][Gameplay]: _enter_state_results() given payload %s." % str(payload))
	fsm.change_state(StateFactory.create(ResultsState, _on_gameplay_state_finished), payload)


# TODO
# payload idea: rematch yes/no
func _on_gameplay_state_finished(payload: Dictionary) -> void:
	print("[State][Primary][Gameplay]: _on_gameplay_state_finished() given payload %s." % str(payload))
	await fsm.change_state(StateBase.new())
	# TODO TEMP: no rematch
	finished.emit()

#endregion

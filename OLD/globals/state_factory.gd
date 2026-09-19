#extends Node
#
#
#enum EState {
	#BOOTING,
	#ATTRACT_MODE,
	#MATCHMAKING,
	#GAMEPLAY,
	#
	#CHARACTER_SELECT,
	#STAGE_SELECT,
	#COMBAT,
	#RESULTS,
#}
#
#
#const enum_to_script : Array[Script] = [
	#preload("res://core/finite_state_machine/primary_game_states/booting_state.gd"),
	#preload("res://core/finite_state_machine/primary_game_states/attract_mode_state.gd"),
	#preload("res://core/finite_state_machine/primary_game_states/matchmaking_state.gd"),
	#preload("res://core/finite_state_machine/primary_game_states/gameplay_state.gd"),
	#
	#preload("res://core/finite_state_machine/primary_game_states/gameplay_states/character_select_state.gd"),
	#preload("res://core/finite_state_machine/primary_game_states/gameplay_states/stage_select_state.gd"),
	#preload("res://core/finite_state_machine/primary_game_states/gameplay_states/combat_state.gd"),
	#preload("res://core/finite_state_machine/primary_game_states/gameplay_states/results_state.gd"),
#]
#
#
### Creates a state object, assigns [param finishedCallback] to the object's
### [signal StateBase.finished] as a one shot, and returns it.
#func create(stateEnum: EState, finishedCallback: Callable) -> StateBase:
	#var state = enum_to_script[stateEnum].new()
	#if state is StateBase:
		#state.finished.connect(finishedCallback, CONNECT_ONE_SHOT)
		#return state
	#else:
		#push_error("StateFactory.create_state() was given a stateClass value that is not a StateBase.")
		#return null

extends Node


const IDLE := 0

const BOOTING := 1
const ATTRACT_MODE := 2
const MATCHMAKING := 3
const GAMEPLAY := 4

const CHARACTER_SELECT := 5
const STAGE_SELECT := 6
const COMBAT := 7
const RESULTS := 8


const enum_to_script : Array[Script] = [
	preload("res://core/finite_state_machine/state_base.gd"),
	
	preload("res://core/finite_state_machine/primary_game_states/booting_state.gd"),
	preload("res://core/finite_state_machine/primary_game_states/attract_mode_state.gd"),
	preload("res://core/finite_state_machine/primary_game_states/matchmaking_state.gd"),
	preload("res://core/finite_state_machine/primary_game_states/gameplay_state.gd"),
	
	preload("res://core/finite_state_machine/primary_game_states/gameplay_states/character_select_state.gd"),
	preload("res://core/finite_state_machine/primary_game_states/gameplay_states/stage_select_state.gd"),
	preload("res://core/finite_state_machine/primary_game_states/gameplay_states/combat_state.gd"),
	preload("res://core/finite_state_machine/primary_game_states/gameplay_states/results_state.gd"),
]


func create_state(stateId: int) -> StateBase:
	return enum_to_script[stateId].new()

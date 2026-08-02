extends GameMode
class_name MultiplayerGameMode
## For multiplayer 1v1.[br]
## [br]
## When [method MultiplayerGameMode.start] is called, multiplayer peer must
## already be set up.


var _temp_mech_to_load := preload("res://entities/mech_characters/mech_guy/mech_guy.tscn")


func start() -> void:
	Debug.print_info("MultiplayerGameMode starting!")
	# TODO: choose level (randomly?)
	_main_scene.spawn_level(StageRefs.get_stage(StageRefs.EStage.DEV))
	# TODO: allow players to choose character, then spawn characters
	
	_main_scene.spawn_mech(
		_temp_mech_to_load, 1,
		_temp_mech_to_load, _main_scene.multiplayer.get_peers()[0], 0
	)

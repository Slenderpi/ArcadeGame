extends GameMode
class_name MultiplayerGameMode
## For multiplayer 1v1.[br]
## [br]
## When [method MultiplayerGameMode.start] is called, multiplayer peer must
## already be set up.



func start() -> void:
	Debug.print_success("[GameMode]: MultiplayerGameMode starting!")
	# TODO: choose level (randomly?)
	_main_scene.spawn_stage(StageRefs.get_stage(StageRefs.EStage.DEV))
	# TODO: allow players to choose character, then spawn characters
	
	_main_scene.spawn_mechs(
		MechRefs.EMech.MECH_GUY, 1,
		MechRefs.EMech.MECH_GUY, 1
	)

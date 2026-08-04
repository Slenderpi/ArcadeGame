extends GameMode
class_name SingleplayerGameMode


func start() -> void:
	Debug.print_success("[GameMode]: SingleplayerGameMode starting!")
	_main_scene.spawn_stage(StageRefs.get_stage(StageRefs.EStage.DEV))
	
	_main_scene.spawn_mechs(
		MechRefs.EMech.MECH_GUY, 1,
		MechRefs.EMech.MECH_GUY, 2
	)

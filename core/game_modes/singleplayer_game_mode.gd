extends GameMode
class_name SingleplayerGameMode


func start() -> void:
	Debug.print_info("SingleplayerGameMode starting!")
	_main_scene.spawn_level(StageRefs.get_stage(StageRefs.EStage.DEV))
	
	_main_scene.spawn_mech(
		MechRefs.EMech.MECH_GUY, 1,
		MechRefs.EMech.MECH_GUY, 2
	)

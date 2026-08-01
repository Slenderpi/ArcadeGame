extends GameMode
class_name MultiplayerGameMode
## For multiplayer 1v1.


func start() -> void:
	Debug.print_info("MultiplayerGameMode starting!")
	# TODO: choose level (randomly?)
	_main_scene.spawn_level(StageRefs.get_stage(StageRefs.EStage.DEV))
	# TODO: allow players to choose character, then spawn characters

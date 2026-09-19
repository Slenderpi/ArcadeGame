@abstract
extends RefCounted
class_name GameMode
## Base class for all [GameMode] objects.
## All game modes created should be given an enum value in
## [enum GameMode.EMode]


## Enum holding the different mode subclases.
# NOTE: Might not use this
enum EMode {
	TRAINING,
	SINGLEPLAYER,
	MULTIPLAYER
}


var _main_scene: MainScene


func _init(mainSceneOwner: MainScene) -> void:
	_main_scene = mainSceneOwner


## Triggers the [GameMode] to begin.
func start() -> void:
	Debug.print_success("[GameMode]: start() has been called.")

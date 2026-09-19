extends Node
class_name UiManager


@export_group("References")
@export
var _attraction_mode_canvas : AttractionModeCanvas
@export
var _matchmaking_canvas : MatchmakingCanvas
@export
var _dev_canvas : DevCanvas

#var _main_scene : MainScene


func _ready() -> void:
	_attraction_mode_canvas.hide()
	_matchmaking_canvas.hide()
	_dev_canvas.show()


func show_attraction_mode() -> void:
	_attraction_mode_canvas.show()
	# TODO: _gameplay_canvas.hide()


func show_matchmaking() -> void:
	_matchmaking_canvas.show()


func show_gameplay() -> void:
	_attraction_mode_canvas.hide()
	_matchmaking_canvas.hide()
	# TODO: _gameplay_canvas.show()


#func on_main_scene_state_changed() -> void:
	#match _main_scene.state:
		#MainScene.EMainSceneState.ATTRACTION_MODE:
			#_attraction_mode_canvas.show()
			##_dev_canvas.mech_character = null
		#MainScene.EMainSceneState.MATCHMAKING:
			#_matchmaking_canvas.show()
		#MainScene.EMainSceneState.SINGLEPLAYER, MainScene.EMainSceneState.MULTIPLAYER:
			#_matchmaking_canvas.hide()
			#_attraction_mode_canvas.hide()


func on_matchmaking_result(foundPeer: bool) -> void:
	_matchmaking_canvas.on_matchmaking_result(foundPeer)


func on_versus_found() -> void:
	_matchmaking_canvas.show()
	_matchmaking_canvas.on_matchmaking_result(true)


func on_mech_spawned(mechChar: MechCharacter) -> void:
	_dev_canvas.mech_character = mechChar
	_dev_canvas.show()

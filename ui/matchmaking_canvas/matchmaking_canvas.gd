extends CanvasBase
class_name MatchmakingCanvas


@export_group("Config")
## In deg per second
@export
var _loading_circle_rotation_speed : float = 360

@export_group("References")
@export
var _searching_dialogue_box : Control
@export
var _findingopp_loading_circle : Control
@export
var _multiplayer_dialogue_box : Control
@export
var _singleplayer_dialogue_box : Control


func _init() -> void:
	_on_hide.call_deferred()


func _process(delta: float) -> void:
	if visible:
		_findingopp_loading_circle.rotation += delta * deg_to_rad(_loading_circle_rotation_speed)


func _on_show() -> void:
	_searching_dialogue_box.show()


func _on_hide() -> void:
	_searching_dialogue_box.hide()
	_multiplayer_dialogue_box.hide()
	_singleplayer_dialogue_box.hide()


func on_matchmaking_result(foundPeer: bool) -> void:
	_searching_dialogue_box.hide()
	if foundPeer:
		_multiplayer_dialogue_box.show()
	else:
		_singleplayer_dialogue_box.show()

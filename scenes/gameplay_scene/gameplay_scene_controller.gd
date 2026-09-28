extends SceneController
class_name GameplaySceneController


@onready
var game_board : GameBoard = $GameBoard
@onready
var camera : Camera3D = $Camera3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TransitionManager.set_queued_transition(TransitionManager.TRANSITION_FANCY_DOORS)
	camera.transform = game_board.camtrans.transform


func _update(_delta: float) -> void:
	pass

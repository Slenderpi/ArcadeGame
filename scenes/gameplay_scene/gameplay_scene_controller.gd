extends SceneController
class_name GameplaySceneController


@onready
var game_board : GameBoard = $GameBoard


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TransitionManager.set_queued_transition(TransitionManager.TRANSITION_FANCY_DOORS)


func _update(_delta: float) -> void:
	if GameInput.nav_just_pressed && GameInput.nav_type != GameInput.NAV_TYPE_COMBO:
		if GameInput.nav_input.z:
			if game_board.note_speed == game_board.MAX_NOTE_SPEED:
				return
			game_board.note_speed += 1
			print("Note speed now %d" % game_board.note_speed)
		elif GameInput.nav_input.w:
			if game_board.note_speed == 0:
				return
			game_board.note_speed -= 1
			print("Note speed now %d" % game_board.note_speed)

extends SceneController
class_name GameplaySceneController


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TransitionManager.set_queued_transition(TransitionManager.TRANSITION_FANCY_DOORS)


func _update(_delta: float) -> void:
	pass

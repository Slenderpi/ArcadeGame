extends SceneController
class_name AttractModeSceneController


func _ready() -> void:
	TransitionManager.set_queued_transition(TransitionManager.TRANSITION_FANCY_DOORS)


#func _update() -> void:
	#if 

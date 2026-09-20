extends SceneController
class_name BootingSceneController
## The first [SceneController] the game enters into.[br]
## Disables physics servers (2D and 3D).


func _ready() -> void:
	PhysicsServer2D.set_active(false)
	PhysicsServer3D.set_active(false)

extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation = Vector3.ZERO


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_x(delta * 0.1)
	rotate_y(delta * 0.3)
	rotate_z(delta * 0.4)

extends MeshInstance3D

@export_range(0.1, 3, 0.1)
var radius := 2.0
@export_range(0.1, 2, 0.1)
var duration := 1.0

var _start_pos : Vector3


func _ready() -> void:
	_start_pos = position


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 * TAU
	var x := radius * cos(t / duration)
	var z := radius * sin(t / duration)
	position.x = _start_pos.x + x
	position.y = _start_pos.y
	position.z = _start_pos.z + z

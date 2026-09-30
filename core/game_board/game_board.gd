@tool
extends Node
class_name GameBoard


signal board_config_changed()


@export_group("Board Config")

@warning_ignore("unused_private_class_variable")
@export_tool_button("Force Emit Board Config Changed", "Signals")
var _force_board_update = _on_force_emit_property_changed_button

@export_range(1, 40, 1, "prefer_slider")
var strip_count: int:
	get:
		return _strip_count
	set(value):
		_strip_count = value
		_on_board_config_property_changed()

@export_range(0.0, 2.0, 0.01)
var strip_width: float:
	get:
		return _strip_width
	set(value):
		_strip_width = value
		_on_board_config_property_changed()


@onready
var camtrans : Node3D = $CameraTransform
@onready
var note_pool: NotePool = $NotePool

var startX : float:
	get:
		return _startX

var start_time: int = 0

# TEST
var _last_note_create_time: int
var _side_flip: = true


var _startX: float
var _strip_count: int = 20
var _strip_width: float = 1.0


func _ready() -> void:
	start_time = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var time: = Time.get_ticks_msec() - start_time
	
	# TEST
	if time - _last_note_create_time >= 1000:
		_last_note_create_time = time
		var note: = note_pool.spawn_step_note()
		note.position = Vector3(-1 if _side_flip else 1, 0, 0)
		note.set_visuals_for_side(_side_flip)
		note.show()
		_side_flip = not _side_flip


func _on_force_emit_property_changed_button():
	print("Force emitting board_config_changed signal.")
	_on_board_config_property_changed()


func _on_board_config_property_changed():
	_startX = (strip_count - 1) * strip_width * -0.5
	board_config_changed.emit()

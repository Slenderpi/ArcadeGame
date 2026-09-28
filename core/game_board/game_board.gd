@tool
extends Node
class_name GameBoard


signal board_config_changed()


@export_group("Board Config")

@warning_ignore("unused_private_class_variable")
@export_tool_button("Force Emit Board Config Changed", "Signals")
var _force_board_update = _on_force_emit_property_changed_button

@export_range(1, 40, 1, "prefer_slider")
var strip_count : int:
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

var startX : float:
	get:
		return _startX

var _startX: float
var _strip_count : int = 20
var _strip_width : float = 1.0


func _on_force_emit_property_changed_button():
	print("Force emitting board_config_changed signal.")
	_on_board_config_property_changed()


func _on_board_config_property_changed():
	_startX = (strip_count - 1) * strip_width * -0.5
	board_config_changed.emit()

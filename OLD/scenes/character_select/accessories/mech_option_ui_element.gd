extends PanelContainer
class_name MechOptionUiElement


const DEFAULT_BG_COLOR = Color(0.07, 0.107, 0.24, 1.0)
const SELECTED_BG_COLOR = Color(0.302, 0.391, 0.709, 1.0)
const CHOSEN_BG_COLOR = Color(1.0, 0.776, 0.0, 1.0)


@export
var _mech_name : Label
@export
var _colorbg : ColorRect


func _ready() -> void:
	_colorbg.color = DEFAULT_BG_COLOR


func set_mech_name(mechName: String) -> void:
	_mech_name.text = mechName


func on_selected() -> void:
	_colorbg.color = SELECTED_BG_COLOR


func on_deselected() -> void:
	_colorbg.color = DEFAULT_BG_COLOR


func on_chosen() -> void:
	_colorbg.color = CHOSEN_BG_COLOR

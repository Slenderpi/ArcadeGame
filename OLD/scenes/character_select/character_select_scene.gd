extends Node
class_name CharacterSelectScene


var curr_selection : int:
	get:
		return _curr_selection
	set(value):
		set_selection(value)


@export
var _mech_options_container : Container
@export
var cam_target : Node3D
@export
var timer_label : Label
@export
var opponent_choice_mech_name : Label

var time_as_int : int

var _mech_option_ui_element_scene := preload("res://scenes/character_select/accessories/mech_option_ui_element.tscn")

var _instanced_mech_options : Array[MechOptionUiElement] = []
var _curr_selection := 0


func _ready() -> void:
	_instanced_mech_options.clear()
	for metadata in MechRefs.mech_metadata:
		var optionElement : MechOptionUiElement = _mech_option_ui_element_scene.instantiate()
		optionElement.set_mech_name(metadata.mech_name)
		_instanced_mech_options.append(optionElement)
		_mech_options_container.add_child(optionElement)
	_instanced_mech_options[_curr_selection].on_selected()


func set_selection(selection: int) -> void:
	if selection >= _instanced_mech_options.size():
		selection = 0
	elif selection < 0:
		selection = _instanced_mech_options.size() - 1
	_instanced_mech_options[_curr_selection].on_deselected()
	_curr_selection = selection
	_instanced_mech_options[_curr_selection].on_selected()


func on_option_chosen() -> void:
	_instanced_mech_options[_curr_selection].on_chosen()


func set_opponent_choice(option: int) -> void:
	opponent_choice_mech_name.text = MechRefs.mech_metadata[option].mech_name


func set_time_remaining(time: float) -> void:
	var _time := floori(time)
	if _time != time_as_int:
		time_as_int = _time
		timer_label.text = str(time_as_int)
		# Possibly do an animation

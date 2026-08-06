extends CanvasBase
class_name DevCanvas


#@export
#var _controls_display : DevControlsDisplay


var mech_character : MechCharacter:
	get:
		return _mech_character
	set(value):
		_mech_character = value
		_set_children_mech_character_refs()
var _mech_character : MechCharacter


func _set_children_mech_character_refs() -> void:
	#_controls_display._mech_character = mech_character
	pass


func _on_hide() -> void:
	mech_character = null

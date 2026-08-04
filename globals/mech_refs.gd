extends Node


## A mech.
# NOTE: Enum values MUST line up with order in _preloaded_mechs
enum EMech {
	MECH_GUY
}


# Fill with references to each mech scene.
var _preloaded_mechs : Array[PackedScene] = [
	preload("res://entities/mech_characters/mech_guy/mech_guy.tscn")
]


## Instantiates a mech.
func instantiate_mech(mechType: EMech) -> MechCharacter:
	return _preloaded_mechs[mechType].instantiate() as MechCharacter

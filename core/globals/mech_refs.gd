extends Node


## A mech.
# NOTE: Enum values MUST line up with order in _preloaded_mechs
enum EMech {
	MECH_GUY,
	BIG_BLUE
}


# Fill with references to each mech scene.
var _mech_file_refs : Array[String] = [
	"res://entities/mech_characters/mech_guy/mech_guy.tscn",
	"res://entities/mech_characters/big_blue/big_blue.tscn",
]


func get_mech_file(mechType: EMech) -> String:
	return _mech_file_refs[mechType]


## Instantiates a mech.
func instantiate_mech(mechType: EMech) -> MechCharacter:
	return load(get_mech_file(mechType)).instantiate() as MechCharacter

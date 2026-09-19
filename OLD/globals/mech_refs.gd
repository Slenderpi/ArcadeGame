extends Node


## A mech.
# NOTE: Enum values MUST line up with order in _preloaded_mechs
enum EMech {
	MECH_GUY,
	BIG_BLUE,
	RED_ROBIN
}


# Fill with references to each mech scene.
const MECH_FILE_REFS : Array[String] = [
	"res://entities/mech_characters/mech_guy/mech_guy.tscn",
	"res://entities/mech_characters/big_blue/big_blue.tscn",
	"res://entities/mech_characters/red_robin/red_robin.tscn",
]

var mech_metadata : Array[MechMetadata] = [
	# MECH GUY
	MechMetadata.new(
		"Mech Guy"
	),
	MechMetadata.new(
		"Big Blue"
	),
	MechMetadata.new(
		"Red Robin"
	),
]


func get_mech_file(mechType: EMech) -> String:
	return MECH_FILE_REFS[mechType]


## Instantiates a mech.
func instantiate_mech(mechType: EMech) -> MechCharacter:
	return load(get_mech_file(mechType)).instantiate() as MechCharacter


func get_mech_metadata(mechType: EMech) -> MechMetadata:
	return mech_metadata[mechType]

extends RefCounted
class_name MechMetadata
## Holds data about the Mech that's not directly for gameplay, such as
## their name.


var mech_name : String


func _init(
		mechName: String
	):
	mech_name = mechName

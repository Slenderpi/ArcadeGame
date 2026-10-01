extends NoteObject
class_name StepNote


const LEFT_MATERIAL_RSRC = preload("uid://24b55u61opj4")
const RIGHT_MATERIAL_RSRC = preload("uid://dl140m1352mpw")


## Set the visual appearance based on which foot side this note is for.
func set_visuals_for_side(asLeft: bool) -> void:
	set_surface_override_material(0, LEFT_MATERIAL_RSRC if asLeft else RIGHT_MATERIAL_RSRC)

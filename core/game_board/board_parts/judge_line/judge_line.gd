@tool
extends MultiMeshInstance3D
class_name JudgeLine


@export
var game_board_owner : GameBoard:
	get:
		return _game_board_owner
	set(value):
		_game_board_owner = value
		generate_multimesh()

@warning_ignore("unused_private_class_variable")
@export_tool_button("Regenerate MultiMesh", "SliderJoint3D")
var _regen_mesh_tool_button = _regenerate_multimesh_callable

@export
var mesh_instance: Mesh:
	get:
		return _mesh_instance
	set(value):
		_mesh_instance = value
		generate_multimesh()


var _game_board_owner : GameBoard = null
var _mesh_instance : Mesh


func _regenerate_multimesh_callable():
	# NOTE: is a "print_editor()" possible?
	print("Regenerating JudgeLine MultiMesh.")
	generate_multimesh()


func generate_multimesh() -> void:
	if not _game_board_owner:
		#push_warning("[JudgeLine] Please set the game_board_owner for the JudgeLine.")
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true         # Enables set_instance_color
	mm.use_custom_data = true    # Enables set_instance_custom_data (4 extra floats per instance!)
	mm.mesh = _mesh_instance
	mm.instance_count = _game_board_owner.strip_count
	
	for i in range(_game_board_owner.strip_count):
		# Set fixed position in a straight row along the X axis
		var pos := Vector3(_game_board_owner.startX + i * _game_board_owner.strip_width, 0.0, 0.0)
		var trans := Transform3D(Basis(), pos)
		mm.set_instance_transform(i, trans)
		
		# Set default color and initial custom parameters (e.g. brightness = 1.0)
		var colorV : Vector3 = lerp(Vector3(0, 0, 1), Vector3(1, 0, 0), float(i) / (_game_board_owner.strip_count - 1))
		var color : Color = Color(colorV.x, colorV.y, colorV.z)
		mm.set_instance_color(i, color)
		#mm.set_instance_custom_data(i, Color(color, 1))
	
	multimesh = mm


func _on_game_board_board_config_changed() -> void:
	generate_multimesh()

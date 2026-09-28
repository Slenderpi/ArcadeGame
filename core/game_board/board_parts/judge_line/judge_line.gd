@tool
extends MultiMeshInstance3D

@export
@warning_ignore("unused_private_class_variable")
var _regenerate : bool:
	set(value):
		if (value):
			setup_led_strip()

@export_range(1, 40, 1, "prefer_slider")
var count: int:
	get:
		return _count
	set(value):
		_count = value
		setup_led_strip()

@export_range(0.0, 2.0, 0.01)
var mesh_width: float:
	get:
		return _mesh_width
	set(value):
		_mesh_width = value
		setup_led_strip()

@export
var mesh_instance: Mesh:
	get:
		return _mesh_instance
	set(value):
		_mesh_instance = value
		setup_led_strip()


var _count : int = 20
var _mesh_width : float = 1.0
var _mesh_instance : Mesh


func _ready() -> void:
	setup_led_strip()


func setup_led_strip() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true         # Enables set_instance_color
	mm.use_custom_data = true    # Enables set_instance_custom_data (4 extra floats per instance!)
	mm.mesh = _mesh_instance
	mm.instance_count = count
	
	var startX : float = (count - 1) * mesh_width * -0.5
	
	for i in range(count):
		# Set fixed position in a straight row along the X axis
		var pos := Vector3(startX + i * mesh_width, 0.0, 0.0)
		var trans := Transform3D(Basis(), pos)
		mm.set_instance_transform(i, trans)
		
		# Set default color and initial custom parameters (e.g. brightness = 1.0)
		var colorV : Vector3 = lerp(Vector3(0, 0, 1), Vector3(1, 0, 0), float(i) / (count - 1))
		var color : Color = Color(colorV.x, colorV.y, colorV.z)
		mm.set_instance_color(i, color)
		#mm.set_instance_custom_data(i, Color(color, 1))
	
	multimesh = mm

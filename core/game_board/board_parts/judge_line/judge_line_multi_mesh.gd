@tool
extends MultiMeshInstance3D

@export var count: int = 20
@export var spacing: float = 0.5
@export var mesh_to_use: Mesh

@export var generate : bool:
	set(value):
		if value:
			setup_led_strip()

func _ready() -> void:
	setup_led_strip()

func setup_led_strip() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true         # Enables set_instance_color
	mm.use_custom_data = true    # Enables set_instance_custom_data (4 extra floats per instance!)
	mm.mesh = mesh_to_use
	mm.instance_count = count
	
	var startX : float = (count - 1) * spacing * -0.5
	
	for i in range(count):
		# Set fixed position in a straight row along the X axis
		var pos := Vector3(startX + i * spacing, 0.0, 0.0)
		var trans := Transform3D(Basis(), pos)
		mm.set_instance_transform(i, trans)
		
		# Set default color and initial custom parameters (e.g. brightness = 1.0)
		mm.set_instance_color(i, Color.RED)
		mm.set_instance_custom_data(i, Color(1.0, 0.0, 0.0, 0.0)) # Custom Vector4
		
	multimesh = mm

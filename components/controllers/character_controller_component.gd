extends Node
class_name CharacterControllerComponent

@onready var character: MechCharacter = get_parent()

func _physics_process(_delta: float) -> void:
	pass
	## Read input (assuming you've mapped inputs per player, e.g., "move_left_0")
	#var input_dir := Input.get_vector(
		#"move_left_%d" % device_id, 
		#"move_right_%d" % device_id, 
		#"move_forward_%d" % device_id, 
		#"move_backward_%d" % device_id
	#)
	#
	## Call DOWN to the parent character
	#character.set_movement_intent(input_dir)
	#
	#if Input.is_action_just_pressed("attack_%d" % device_id):
		#character.perform_primary_attack()

extends Node3D
class_name GameCamera
## Contains methods and properties for Camera behaviors and effects.[br]
## [br]
## Properties of interest:[br]
## - [member GameCamera.shake_intensity_roll] for camera shake (roll)[br]
## - [member GameCamera.shake_intensity_pitch] for camera shake (pitch)[br]
## - [member GameCamera.shake_intensity_yaw] for camera shake (yaw)[br]


## Determines the different modes a Camera can be in.
enum ECameraMode {
	## The Camera is idle.
	NONE = 0,
	## The Camera sets its position and rotation to [member GameCamera.first_person_target]
	FIRST_PERSON = 1,
	## For debugging purposes. Enables the camera to freely fly around
	## using the WASDEQ keys.
	FREE_FLIGHT = 2,
	## The Camera acts as a third person camera, where
	## [member GameCamera.third_person_target] is the target being followed.
	THIRD_PERSON = 3,
}

## Determines the Camera's current [enum GameCamera.ECameraMode].[br]
## [br]
## When you change this value, [member GameCamera.camera_target] will
## automatically update based on other targeting properties.[br]
## [br]
## For example, setting to [code]ECameraMode.FIRST_PERSON[/code] will set
## [member GameCamera.camera_target] to [member GameCamera.first_person_target].[br]
## [br][br]
## [u][i]ECameraMode values:[/i][/u]
@export var camera_mode : ECameraMode:
	get:
		return _current_camera_mode
	set(value):
		_current_camera_mode = value
		_handle_camera_mode_change()
var _current_camera_mode := ECameraMode.FREE_FLIGHT
## The FOV of the GameCamera (degrees). You should set this value instead of
## [code]Camera3D.fov[/code], since some Camera effects may affect the final fov.[br]
## Note that this is vertical FOV.
@export_range(1, 179, 1)
var desired_fov := 90.0

@export_group("First Person Camera Properties")
## A Node that the Camera will copy the transform of.[br]
## Only used if [member GameCamera.camera_mode] is set to [code]ECameraMode.FirstPerson[/code].[br]
## [br]
## GameCamera will check if the provided node implements [code]get_camera_fps_target() -> Node3D[/code].
## This function is how you can provide a specific [Node3D] child to use as the target.
@export var first_person_target : Node3D = null

#@export var third_person_target: Node3D = null

@export_group("Free Flight Camera Properties")
## Mouse sensitivity for the GameCamera.
@export var free_flight_mouse_sensitivity := 0.07
## Base movement speed for the GameCamera.[br]
## Use [color=cyan]WASDEQ[/color] to move the GameCamera.[br]
## Holding [color=cyan]Shift[/color] makes you move twice as fast.[br]
## Holding [color=cyan]Ctrl[/color] makes you move half as fast.
@export var free_flight_move_speed := 5.0

## Current Node3D being tracked.
var camera_target : Node3D = null

# In radians
var _free_flight_rot := Vector3.ZERO

@export_group("Camera Effect Properties")
@export_subgroup("Shake")
## The camera shake's roll angle (degrees) to apply for each level of
## [member GameCamera.shake_intensity].[br]
## Higher values leads to a shakier-looking camera.
@export_range(0.1, 30.0, 0.1)
var shake_angle_per_intensity := 1.0
## The time (seconds) for a shake cycle to finish (full roll right, then full
## roll left).[br]
## The lower the value, the faster the shake. The higher, the slower.[br]
## [br]
## Does not affect intensity slowing.
@export_range(0.01, 1.0, 0.01)
var shake_cycle_duration := 0.2

## Determines the intensity of camera shake (roll axis).
## At runtime, Camera shake directly follows this value.[br]
## [br]
## This value is automatically calmed down over time.[br]
## [br]
## To shake the Camera, simply set this to some positive value. The Camera will
## then shake a lot, then gradually calm down.[br]
## Similarly, you could stop the shaking by setting this value to 0. Please
## do not provide a negative value.
var shake_intensity_roll : float:
	get:
		return _current_rollshake_intensity
	set(value):
		_current_rollshake_intensity = value
		_last_rollshake_intensity_set_time = Time.get_ticks_msec()
var _current_rollshake_intensity := 0.0
var _last_rollshake_intensity_set_time := 0

## Determines the intensity of camera shake (pitch axis).
## At runtime, Camera shake directly follows this value.[br]
## [br]
## This value is automatically calmed down over time.[br]
## [br]
## To shake the Camera, simply set this to some positive value. The Camera will
## then shake a lot, then gradually calm down.[br]
## Similarly, you could stop the shaking by setting this value to 0. Please
## do not provide a negative value.
var shake_intensity_pitch : float:
	get:
		return _current_pitchshake_intensity
	set(value):
		_current_pitchshake_intensity = value
		_last_pitchshake_intensity_set_time = Time.get_ticks_msec()
var _current_pitchshake_intensity := 0.0
var _last_pitchshake_intensity_set_time := 0

## Determines the intensity of camera shake (yaw axis).
## At runtime, Camera shake directly follows this value.[br]
## [br]
## This value is automatically calmed down over time.[br]
## [br]
## To shake the Camera, simply set this to some positive value. The Camera will
## then shake a lot, then gradually calm down.[br]
## Similarly, you could stop the shaking by setting this value to 0. Please
## do not provide a negative value.
var shake_intensity_yaw : float:
	get:
		return _current_yawshake_intensity
	set(value):
		_current_yawshake_intensity = value
		_last_yawshake_intensity_set_time = Time.get_ticks_msec()
var _current_yawshake_intensity := 0.0
var _last_yawshake_intensity_set_time := 0

@onready var camera : Camera3D = $Camera3D


func _ready() -> void:
	_handle_camera_mode_change()
	camera.fov = desired_fov


func _physics_process(delta: float) -> void:
	_calm_shake_intensity(delta)
	match camera_mode:
		ECameraMode.FIRST_PERSON:
			_handle_camera_mode_fps()
		ECameraMode.FREE_FLIGHT:
			_handle_camera_mode_freeflight(delta)
	_apply_camera_effects(delta)


func _handle_camera_mode_fps() -> void:
	if not camera_target:
		print_rich("[color=yellow]WARNING: Current CameraMode is set to FirstPerson but no FirstPersonTarget is set!")
		return
	var transInterped = camera_target.get_global_transform_interpolated()
	global_position = transInterped.origin
	global_rotation = transInterped.basis.get_euler()


func _handle_camera_mode_freeflight(delta: float) -> void:
	var inputDir : Vector3 = Vector3()
	if Input.is_key_pressed(KEY_W):
		inputDir.z -= 1
	if Input.is_key_pressed(KEY_S):
		inputDir.z += 1
	if Input.is_key_pressed(KEY_A):
		inputDir.x -= 1
	if Input.is_key_pressed(KEY_D):
		inputDir.x += 1
	if Input.is_key_pressed(KEY_Q):
		inputDir.y -= 1
	if Input.is_key_pressed(KEY_E):
		inputDir.y += 1
	var speedMult := 1.0
	if Input.is_key_pressed(KEY_CTRL):
		speedMult *= 0.5
	if Input.is_key_pressed(KEY_SHIFT):
		speedMult *= 2.0
	translate(free_flight_move_speed * speedMult * delta * inputDir.normalized())
	rotation = _free_flight_rot


func _calm_shake_intensity(delta: float) -> void:
	if shake_intensity_roll > 0:
		# TODO: Better parameters/math for intensity calming
		var diff := shake_intensity_roll * 0.88 + 1.0
		_current_rollshake_intensity = max(0, shake_intensity_roll - diff * delta)
	if shake_intensity_pitch > 0:
		# TODO: Better parameters/math for intensity calming
		var diff := shake_intensity_pitch * 0.88 + 1.0
		_current_pitchshake_intensity = max(0, shake_intensity_pitch - diff * delta)
	if shake_intensity_yaw > 0:
		# TODO: Better parameters/math for intensity calming
		var diff := shake_intensity_yaw * 0.88 + 1.0
		_current_yawshake_intensity = max(0, shake_intensity_yaw - diff * delta)


func _apply_camera_effects(_delta: float) -> void:
	# TODO: apply any other necessary Camera effects
	if shake_intensity_roll > 0:
		var currTime := (Time.get_ticks_msec() - _last_rollshake_intensity_set_time) / 1000.0
		var cycleScaledTime := cos(TAU * currTime / shake_cycle_duration)
		camera.rotation.z = shake_intensity_roll * deg_to_rad(shake_angle_per_intensity) * cycleScaledTime
		#print("Time: %f | Shake intensity: %f" % [currTime, shake_intensity])
	if shake_intensity_pitch > 0:
		var currTime := (Time.get_ticks_msec() - _last_pitchshake_intensity_set_time) / 1000.0
		var cycleScaledTime := cos(TAU * currTime / shake_cycle_duration)
		camera.rotation.x = shake_intensity_pitch * deg_to_rad(shake_angle_per_intensity) * cycleScaledTime
		#print("Time: %f | Shake intensity: %f" % [currTime, shake_intensity])
	if shake_intensity_yaw > 0:
		var currTime := (Time.get_ticks_msec() - _last_yawshake_intensity_set_time) / 1000.0
		var cycleScaledTime := cos(TAU * currTime / shake_cycle_duration)
		camera.rotation.y = shake_intensity_yaw * deg_to_rad(shake_angle_per_intensity) * cycleScaledTime
		#print("Time: %f | Shake intensity: %f" % [currTime, shake_intensity])


func _input(event) -> void:
	if event is InputEventMouseMotion:
		if camera_mode == ECameraMode.FREE_FLIGHT:
			var rotH = deg_to_rad(event.relative.x * -free_flight_mouse_sensitivity)
			var rotV = deg_to_rad(event.relative.y * -free_flight_mouse_sensitivity)
			_free_flight_rot.x = clamp(_free_flight_rot.x + rotV, -PI / 2.0, PI / 2.0)
			_free_flight_rot.y = _free_flight_rot.y + rotH
			_free_flight_rot.z = 0
	elif event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_F1:
				camera_mode = ECameraMode.FREE_FLIGHT if camera_mode != ECameraMode.FREE_FLIGHT else ECameraMode.FIRST_PERSON
				print_rich("[color=cyan]DEBUG: GameCamera.camera_mode switched to ", ECameraMode.find_key(camera_mode), " (key: F1).")
			KEY_U:
				# TODO TEMP: this code is purely for testing camera shake
				shake_intensity_roll += 10.0
			KEY_I:
				# TODO TEMP
				shake_intensity_pitch += 10.0
			KEY_O:
				# TODO TEMP
				shake_intensity_yaw += 10.0


func _handle_camera_mode_change() -> void:
	match _current_camera_mode:
		ECameraMode.NONE:
			camera_target = null
		ECameraMode.FIRST_PERSON:
			camera_target = first_person_target
			if first_person_target and first_person_target.has_method("get_camera_fps_target"):
				var camFpsTarget : Node3D = first_person_target.get_camera_fps_target()
				if camFpsTarget:
					camera_target = camFpsTarget
				else:
					print_rich("[color=yellow]WARNING: The FirstPersonTarget set implements the get_camera_fps_target() function, but returned null. Please return a valid Node3D.")
		ECameraMode.FREE_FLIGHT:
			_free_flight_rot = rotation
			_free_flight_rot.z = 0 # Remove roll

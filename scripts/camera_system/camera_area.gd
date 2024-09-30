extends Area3D
class_name CameraArea

@export var assigned_camera : Camera3D

func _ready():
	if not assigned_camera: push_error("No Camera Assigned")
	pass #body_entered.connect(_player_entered)


func _process(delta):
	if has_overlapping_bodies():
		assigned_camera.make_current()


func _player_entered(_body):
	if not assigned_camera: 
		push_error("No Camera Assigned")
		return
	
	assigned_camera.make_current()

extends Node3D
class_name HallwayPiece

@export var connection_markers : Array[ConnectionMarker]
@export var cam_configs_holder : Node3D
@export var clearance_area : StaticBody3D


func _ready():
	assert(connection_markers, "No Connection Markers")
	assert(clearance_area, "No Clearance Area")
	
	_check_for_cam_configs()


func _check_for_cam_configs():
	if not cam_configs_holder: 
		push_error("No Cam Config Holder")
		return
	
	var atleast_one_config = false
	
	for child in cam_configs_holder.get_children():
		if child is CameraConfiguration: 
			atleast_one_config = true
			break
	
	if not atleast_one_config: push_error("No Camera Configs")

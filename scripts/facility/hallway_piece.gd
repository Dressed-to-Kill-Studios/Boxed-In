extends Node3D
class_name HallwayPiece

signal obstructed_placement(hallway_piece : HallwayPiece)

@export var clearance_area : Area3D
@export var connection_markers : Array[ConnectionMarker]


func _ready():
	pass #_check_placement()


func _connect_camera_areas():
	pass


func _set_active_camera():
	pass


func _check_placement():
	if clearance_area.has_overlapping_areas(): obstructed_placement.emit(self)

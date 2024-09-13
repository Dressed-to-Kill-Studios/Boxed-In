extends Node3D
class_name HallwayPiece

@export var connection_markers : Array[ConnectonMarker]
@export var clearance_area : Area3D


func is_placement_clear() -> bool:
	var is_cleared = !clearance_area.has_overlapping_bodies()
	return is_cleared

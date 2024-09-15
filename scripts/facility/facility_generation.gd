@tool
extends Node3D

const HALLWAYS : Dictionary = {
	"end" : preload("res://scenes/hallway_pieces/hallway_end.tscn"),
	"straight" : preload("res://scenes/hallway_pieces/hallway_straight.tscn"),
	"L shape" : preload("res://scenes/hallway_pieces/hallway_L.tscn"),
	"T shape" : preload("res://scenes/hallway_pieces/hallway_T.tscn"),
	"plus shape" : preload("res://scenes/hallway_pieces/hallway_plus.tscn"),
}

@export var generate : bool = false : set = _set_generate
@export var clear : bool = false : set = _set_clear
@export var max_depth : int = 5

var used_markers : Dictionary = {}  # Dictionary to track used markers


func generate_facility():
	_start_generation()


func clear_facility():
	for child in get_children():
		child.queue_free()


func _set_generate(_value):
	generate_facility()


func _set_clear(_value):
	clear_facility()


func _start_generation():
	var start_piece : PackedScene = _get_random_hallway_piece()
	_place_piece_at_marker(%Origin, start_piece, null, 0)


func _place_piece_at_marker(previous_marker : ConnectonMarker, packed_piece : PackedScene, previous_piece : HallwayPiece, current_depth : int):
	if current_depth >= max_depth:
		packed_piece = HALLWAYS["end"]
	
	# Place the new piece
	var piece_instance : HallwayPiece = packed_piece.instantiate()
	add_child(piece_instance, true)
	piece_instance.set_owner(self.get_parent())
	
	if previous_marker == null:
		# If this is the starting piece, no need for transformation
		return
	
	# Find the connection marker for the new piece that should attach to the previous_marker
	var new_marker : ConnectonMarker = piece_instance.connection_markers.pick_random()  # Ensure correct marker selection
	
	# Calculate the rotation needed
	var previous_marker_forward = previous_marker.global_transform.basis.z.normalized()
	var new_marker_forward = new_marker.global_transform.basis.z.normalized()
	
	var rotation_axis = previous_marker_forward.cross(new_marker_forward).normalized()
	var rotation_angle = acos(previous_marker_forward.dot(new_marker_forward))
	
	# Create the rotation quaternion
	var rotation_quat : Quaternion
	if rotation_angle < 0.001:
		# If the angle is very small, no significant rotation is needed
		rotation_quat = Quaternion()
	else:
		rotation_quat = Quaternion(rotation_axis, rotation_angle)
	
	# Apply the rotation to the piece_instance
	piece_instance.global_transform.basis = Basis(rotation_quat) * piece_instance.global_transform.basis
	
	# Calculate the position offset after applying the rotation
	var target_position = previous_marker.global_transform.origin  # Position of the previous marker
	var current_marker_position = new_marker.global_transform.origin  # Position of the new piece's marker
	
	# The marker's position in the local space of the piece_instance
	var local_marker_position = piece_instance.to_local(current_marker_position)
	
	# Adjust the position offset
	var rotated_marker_position = piece_instance.to_global(local_marker_position)
	var position_offset = target_position - rotated_marker_position
	piece_instance.global_transform.origin += position_offset
	
	# Track the new_marker as used in our dictionary
	used_markers[previous_marker] = true
	used_markers[new_marker] = true
	
	print("Piece instance: ", piece_instance)
	print("Marker connected to: ", previous_marker)
	print("On: ", previous_piece)
	print("Using: ", new_marker)
	print("Position Offset: ", position_offset)
	print("Rotation Quaternion: ", rotation_quat)
	print("\n")
	
	# Add connecting pieces recursively
	var connection_points : Array[ConnectonMarker] = piece_instance.connection_markers
	for marker in connection_points:
		if used_markers.has(marker):
			continue
		
		var chosen_piece = _get_random_hallway_piece()
		_place_piece_at_marker(marker, chosen_piece, piece_instance, current_depth + 1)


func _get_random_hallway_piece() -> PackedScene:
	return HALLWAYS.get(HALLWAYS.keys().pick_random())

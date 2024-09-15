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
	for child in get_children(): child.queue_free()


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
	var new_marker : ConnectonMarker = piece_instance.connection_markers[0]  # Assuming the first marker, but this could be dynamic
	
	# Calculate the position offset: move new_piece so its new_marker aligns with previous_marker
	var target_position = previous_marker.global_transform.origin  # Position of the previous marker
	var current_marker_position = new_marker.global_transform.origin  # Position of the new piece's marker
	var position_offset = target_position - current_marker_position
	piece_instance.global_transform.origin += position_offset
	
	# Rotate the new piece so the new_marker's Z-axis aligns with the direction to previous_marker
	var direction = (previous_marker.global_transform.origin - new_marker.global_transform.origin).normalized()
	var up_vector = Vector3.UP
	
	# Apply the rotation to align the piece's Z axis with the direction vector
	piece_instance.look_at(previous_marker.global_transform.origin, up_vector)
	
	# Track the new_marker as used in our dictionary
	used_markers[new_marker] = true
	
	print(str(piece_instance) + "\n" + "Marker connected to: " + str(previous_marker) + "\n" + "On: " + str(previous_piece) + "\n")
	
	# Add connecting pieces recursively
	var connection_points : Array[ConnectonMarker] = piece_instance.connection_markers
	for marker in connection_points:
		if used_markers.has(marker): continue
		
		var chosen_piece = _get_random_hallway_piece()
		_place_piece_at_marker(marker, chosen_piece, piece_instance, current_depth + 1)


func _get_random_hallway_piece() -> PackedScene:
	return HALLWAYS.get(HALLWAYS.keys().pick_random())

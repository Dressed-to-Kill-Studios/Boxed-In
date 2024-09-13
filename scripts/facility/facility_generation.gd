@tool
extends Node

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
	if current_depth >= max_depth: return
	
	#Place piece
	var piece_instance : HallwayPiece = packed_piece.instantiate()
	add_child(piece_instance)
	piece_instance.set_owner(self.get_parent())
	
	var pos_offset = piece_instance.connection_markers[0].global_position - piece_instance.global_position
	piece_instance.global_rotation = previous_marker.global_rotation
	piece_instance.global_position -= pos_offset
	
	#Add connecting pieces
	var connection_points : Array[ConnectonMarker] = piece_instance.connection_markers
	for marker in connection_points:
		var chosen_piece = _get_random_hallway_piece()
		
		_place_piece_at_marker(marker, chosen_piece, piece_instance, current_depth + 1)


func _get_random_hallway_piece() -> PackedScene:
	return HALLWAYS.get(HALLWAYS.keys().pick_random())

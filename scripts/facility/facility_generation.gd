@tool
extends Node3D

signal generation_finished

const HALLWAY_BLOCKAGE = preload("res://scenes/hallway_pieces/hallway_blockage.tscn")
const HALLWAYS : Dictionary = {
	"end" : preload("res://scenes/hallway_pieces/hallway_end.tscn"),
	"straight" : preload("res://scenes/hallway_pieces/hallway_straight.tscn"),
	"L shape" : preload("res://scenes/hallway_pieces/hallway_L.tscn"),
	"T shape" : preload("res://scenes/hallway_pieces/hallway_T.tscn"),
	"plus shape" : preload("res://scenes/hallway_pieces/hallway_plus.tscn"),
}

@export var generate : bool = false : set = _set_generate
@export var clear : bool = false : set = _set_clear
@export_range(0, 10) var max_depth : int = 5
@export var hallway_weights : Dictionary = {
	"end" : 1,
	"straight" : 10,
	"L shape" : 25,
	"T shape" : 20,
	"plus shape" : 15
}
@export_flags_3d_physics var clearance_collision_layer = 1

var used_markers : Dictionary = {}


func generate_facility():
	clear_facility()
	_start_generation()


func clear_facility():
	for child in get_children():
		child.queue_free()
	used_markers.clear()  # Clear the marker dictionary


func _set_generate(_value):
	generate_facility()


func _set_clear(_value):
	clear_facility()


func _start_generation():
	var start_piece : PackedScene = _get_random_hallway_piece()
	_place_piece_at_marker(%Origin, start_piece, null, 0)


func _place_piece_at_marker(previous_marker : ConnectionMarker, packed_piece : PackedScene, previous_piece : HallwayPiece, current_depth : int):
	# Physics ray check for collisions ahead
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = previous_marker.global_transform.origin + Vector3.UP * 4.5
	ray_query.to = ray_query.from + previous_marker.global_transform.basis.z.normalized() * 30  # 30 units forward
	ray_query.collision_mask = clearance_collision_layer
	
	if not previous_piece:
		ray_query.exclude = [%SafeRoomClearnaceArea]  # Exclude the safe room area
	
	var result = get_world_3d().direct_space_state.intersect_ray(ray_query)
	
	if result and previous_piece:
		# If there's a collision, place a blockage and stop
		_place_blockage_at_marker(previous_marker)
		return
	
	# Physics frame to ensure collision detection is accurate
	await get_tree().physics_frame
	
	if current_depth >= max_depth:
		packed_piece = HALLWAYS["end"]
	
	# Place the new piece
	var piece_instance : HallwayPiece = packed_piece.instantiate()
	add_child(piece_instance, true)
	piece_instance.set_owner(self.get_parent())
	
	if previous_marker == null:
		return  # If this is the starting piece, no need for transformation
	
	# Align the new piece with the previous marker
	var new_marker : ConnectionMarker = piece_instance.connection_markers.pick_random()
	_align_piece_to_marker(piece_instance, previous_marker, new_marker)
	
	# Track the markers in the dictionary
	used_markers[previous_marker] = true
	used_markers[new_marker] = true
	
	# Recursively add connecting pieces
	await _connect_new_pieces(piece_instance, current_depth)


func _align_piece_to_marker(piece_instance : HallwayPiece, previous_marker : ConnectionMarker, new_marker : ConnectionMarker):
	var previous_marker_forward = previous_marker.global_transform.basis.z.normalized()
	var new_marker_forward = new_marker.global_transform.basis.z.normalized()
	
	var rotation_axis = previous_marker_forward.cross(new_marker_forward).normalized()
	var rotation_angle = acos(previous_marker_forward.dot(new_marker_forward))
	
	var rotation_quat : Quaternion
	if rotation_angle < 0.001:
		rotation_quat = Quaternion()  # No significant rotation needed
	else:
		rotation_quat = Quaternion(rotation_axis, rotation_angle)
	
	# Apply the rotation to the piece_instance
	piece_instance.global_transform.basis = Basis(rotation_quat) * piece_instance.global_transform.basis
	
	# If the markers are almost parallel, rotate the new piece by 180 degrees
	new_marker_forward = new_marker.global_transform.basis.z.normalized()
	if new_marker_forward.dot(previous_marker_forward) > 0.99:
		var correction_quat = Quaternion(Vector3.UP, PI)  # Rotate 180 degrees
		piece_instance.global_transform.basis = Basis(correction_quat) * piece_instance.global_transform.basis
	
	# Align the position
	var position_offset = previous_marker.global_transform.origin - new_marker.global_transform.origin
	piece_instance.global_transform.origin += position_offset


func _connect_new_pieces(piece_instance : HallwayPiece, current_depth : int):
	var connection_points : Array[ConnectionMarker] = piece_instance.connection_markers
	for marker in connection_points:
		if used_markers.has(marker):
			continue
		
		var chosen_piece = _get_random_hallway_piece()
		_place_piece_at_marker.call_deferred(marker, chosen_piece, piece_instance, current_depth + 1)
		await get_tree().create_timer(2)


func _place_blockage_at_marker(marker : ConnectionMarker):
	var blockage_instance = HALLWAY_BLOCKAGE.instantiate()
	add_child(blockage_instance, true)
	blockage_instance.set_owner(self.get_parent())
	
	blockage_instance.global_transform = marker.global_transform


func _get_random_hallway_piece() -> PackedScene:
	var total_weight : int = 0
	for weight in hallway_weights.values():
		total_weight += weight
	
	var random_value : float = randf() * total_weight
	var accumulated_weight : int = 0
	
	for hallway_type in HALLWAYS.keys():
		accumulated_weight += hallway_weights[hallway_type]
		if random_value < accumulated_weight:
			return HALLWAYS[hallway_type]
	
	return HALLWAYS["end"]  # Fallback to a default piece if something goes wrong

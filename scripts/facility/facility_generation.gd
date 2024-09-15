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
@export_flags_3d_physics var clearance_collision_layer = 1

var used_markers : Dictionary = {}


func generate_facility():
	clear_facility()
	_start_generation()
	
	_check_overlaps()

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


func _place_piece_at_marker(previous_marker : ConnectionMarker, packed_piece : PackedScene, previous_piece : HallwayPiece, current_depth : int):
	# Create a raycast to detect potential collisions
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = previous_marker.global_transform.origin + Vector3.UP * 4.5
	ray_query.to = ray_query.from + previous_marker.global_transform.basis.z.normalized() * 30  # 30 units forward
	ray_query.collision_mask = clearance_collision_layer
	
	if not previous_piece: ray_query.exclude = [%SafeRoomClearnaceArea]
	
	var result = get_world_3d().direct_space_state.intersect_ray(ray_query)
	
	if result and previous_piece: # Hit something
		_place_blockage_at_marker(previous_marker)
		return # No need to place a piece if blockage is placed
	
	await get_tree().physics_frame
	
	if current_depth >= max_depth: packed_piece = HALLWAYS["end"]
	
	# Place the new piece
	var piece_instance : HallwayPiece = packed_piece.instantiate()
	add_child(piece_instance, true)
	piece_instance.set_owner(self.get_parent())
	
	if previous_marker == null: return # If this is the starting piece, no need for transformation
	
	# Find the connection marker for the new piece that should attach to the previous_marker
	var new_marker : ConnectionMarker = piece_instance.connection_markers.pick_random()
	
	# Calculate the rotation needed
	var previous_marker_forward = previous_marker.global_transform.basis.z.normalized()
	var new_marker_forward = new_marker.global_transform.basis.z.normalized()
	
	var rotation_axis = previous_marker_forward.cross(new_marker_forward).normalized()
	var rotation_angle = acos(previous_marker_forward.dot(new_marker_forward))
	
	# Create and initialize the rotation quaternion
	var rotation_quat : Quaternion
	if rotation_angle < 0.001:
		rotation_quat = Quaternion()  # No significant rotation needed
	else:
		rotation_quat = Quaternion(rotation_axis, rotation_angle)
	
	# Apply the rotation to the piece_instance
	piece_instance.global_transform.basis = Basis(rotation_quat) * piece_instance.global_transform.basis
	
	# After rotating the piece, check if the markers are facing the same way
	new_marker_forward = new_marker.global_transform.basis.z.normalized()  # Recalculate the new forward vector after rotation
	
	if new_marker_forward.dot(previous_marker_forward) > 0.99:
		# If the new marker is facing the same way as the previous one (almost parallel), rotate it 180 degrees
		var correction_quat = Quaternion(Vector3.UP, PI)  # Rotate 180 degrees around the up axis
		piece_instance.global_transform.basis = Basis(correction_quat) * piece_instance.global_transform.basis
	
	# Calculate the position offset after applying the rotation
	var target_position = previous_marker.global_transform.origin  # Position of the previous marker
	var current_marker_position = new_marker.global_transform.origin  # Position of the new piece's marker
	
	# The marker's position in the local space of the piece_instance
	var local_marker_position = piece_instance.to_local(current_marker_position)
	
	# Adjust the position offset
	var rotated_marker_position = piece_instance.to_global(local_marker_position)
	var position_offset = target_position - rotated_marker_position
	piece_instance.global_transform.origin += position_offset
	
	# Track the new_marker and previous_marker as used in our dictionary
	used_markers[previous_marker] = true
	used_markers[new_marker] = true
	
	await get_tree().physics_frame
	
	# Add connecting pieces recursively
	var connection_points : Array[ConnectionMarker] = piece_instance.connection_markers
	for marker in connection_points:
		if used_markers.has(marker): continue
		
		var chosen_piece = _get_random_hallway_piece()
		_place_piece_at_marker.call_deferred(marker, chosen_piece, piece_instance, current_depth + 1)
		
		await get_tree().physics_frame
	
	await get_tree().physics_frame
	_check_overlaps()


func _check_overlaps():
	var tolerance = 0.01  # Tolerance for floating-point precision in position comparison
	
	var pieces_to_be_deleted = []
	
	for piece in get_children():
		
		if pieces_to_be_deleted.has(piece): continue
		
		for check_piece in get_children():
			if check_piece == piece: continue
			if pieces_to_be_deleted.has(check_piece): continue
			if not check_piece is HallwayPiece: continue
			
			var dist_between_pieces = piece.global_position.distance_to(check_piece.global_position)
			
			if not dist_between_pieces < tolerance: continue
			
			pieces_to_be_deleted.append(piece)
			pieces_to_be_deleted.append(check_piece)
			
			print("Deleted: %s and the piece overlapping(%s)" % [piece, check_piece])
	
	await get_tree().physics_frame
	_check_open_markers()


func _check_open_markers():
	var tolerance = 0.01  # Tolerance for floating-point precision in position comparison
	
	for marker in used_markers:
		if not is_instance_valid(marker): # Check if marker still exists
				used_markers.erase(marker)
				continue
		
		var marker_position = marker.global_transform.origin
		var found_overlap = false
		
		# Check if any other marker is at the same position
		for check_marker in used_markers:
			if marker == check_marker: continue  # Skip comparing the marker to itself
			if not is_instance_valid(check_marker): # Check if marker still exists
				used_markers.erase(check_marker)
				continue
			
			var check_marker_position = check_marker.global_transform.origin
			
			# Compare positions using a tolerance
			if marker_position.distance_to(check_marker_position) < tolerance:
				found_overlap = true
				break  # No need to check further if we found an overlap
		
		# If no overlap was found, place a blockage at the marker
		if not found_overlap and marker != %Origin:
			print("No marker at the same position, placing blockage at marker: ", marker)
			
			used_markers[marker]
			await get_tree().physics_frame
			_place_blockage_at_marker(marker)


func _place_blockage_at_marker(marker : ConnectionMarker):
	var blockage_instance = HALLWAY_BLOCKAGE.instantiate()
	add_child(blockage_instance, true)
	blockage_instance.set_owner(self.get_parent())
	
	blockage_instance.global_transform = marker.global_transform


func _get_random_hallway_piece() -> PackedScene:
	return HALLWAYS.get(HALLWAYS.keys().pick_random())

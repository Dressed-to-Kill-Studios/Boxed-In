@tool
extends Node3D

signal generation_finished

const STORAGE_ROOM = preload("res://scenes/storage_room/storage_room.tscn")
const HALLWAY_BLOCKAGE = preload("res://scenes/hallway_pieces/hallway_blockage.tscn")
const HALLWAYS : Dictionary = {
	"end" : preload("res://scenes/hallway_pieces/hallway_end.tscn"),
	"straight" : preload("res://scenes/hallway_pieces/hallway_straight.tscn"),
	"L shape" : preload("res://scenes/hallway_pieces/hallway_L.tscn"),
	"T shape" : preload("res://scenes/hallway_pieces/hallway_T.tscn"),
	"plus shape" : preload("res://scenes/hallway_pieces/hallway_plus.tscn"),
}

@export var add_hallways : bool = false : set = _set_add_hallways
@export var add_storage_rooms : bool = false : set = _set_add_storage_rooms
@export var clear : bool = false : set = _set_clear
@export var clear_rooms : bool = false : set = _set_clear_rooms
@export var max_depth : int = 5
@export var creat_loops : bool = true
@export var hallway_weights : Dictionary = {
	"end" : 1,
	"straight" : 10,
	"L shape" : 15,
	"T shape" : 20,
	"plus shape" : 25
}
@export_flags_3d_physics var clearance_collision_layer = 1

@export var hallways_holder : Node3D
@export var storage_rooms_holder : Node3D

var current_depth : int = 0
var free_markers : Array = []


func generate_facility():
	generate_hallways()
	await generation_finished
	generate_storage_rooms()


func generate_hallways():
	clear_facility()
	await get_tree().create_timer(0.25).timeout
	_start_generation()


func generate_storage_rooms():
	for hallway in hallways_holder.get_children():
		
		if not hallway is HallwayPiece: continue
		
		for marker in hallway.storage_room_markers:
			var storage_room_instance = STORAGE_ROOM.instantiate()
			
			storage_rooms_holder.add_child(storage_room_instance, true)
			storage_room_instance.set_owner(self.get_parent())
			
			storage_room_instance.global_transform = marker.global_transform


func clear_facility():
	_clear_rooms()
	for child in hallways_holder.get_children(): child.queue_free()
	free_markers.clear()  # Clear free markers
	current_depth = 0


func _set_add_hallways(_value):
	generate_hallways()


func _set_add_storage_rooms(_value):
	_clear_rooms()
	generate_storage_rooms()


func _set_clear(_value):
	clear_facility()


func _set_clear_rooms(_value):
	_clear_rooms()


func _clear_rooms():
	for child in storage_rooms_holder.get_children(): child.queue_free()


func _start_generation():
	current_depth = 0
	
	var start_piece : PackedScene = _get_random_hallway_piece()
	_place_piece_at_marker(%Origin, start_piece)


func _place_piece_at_marker(previous_marker : ConnectionMarker, packed_piece : PackedScene):
	# Physics ray check for collisions ahead
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = previous_marker.global_transform.origin + Vector3.UP * 4.5
	ray_query.to = ray_query.from + previous_marker.global_transform.basis.z.normalized() * 30  # 30 units forward
	ray_query.collision_mask = clearance_collision_layer
	
	@warning_ignore("incompatible_ternary")
	var result = get_world_3d().direct_space_state.intersect_ray(ray_query) if current_depth != 0 else null
	
	if result:
		# If there's a collision, and can't loop, place a blockage and stop
		if not _check_if_looped(previous_marker) or not creat_loops:
			_place_blockage_at_marker(previous_marker)
		
		_process_free_markers()
		return
	
	await get_tree().physics_frame
	
	if current_depth >= max_depth: packed_piece = HALLWAYS["end"]
	
	# Place the new piece
	var piece_instance : HallwayPiece = packed_piece.instantiate()
	hallways_holder.add_child(piece_instance, true)
	piece_instance.set_owner(self.get_parent())
	
	# Align the new piece with the previous marker
	var new_marker : ConnectionMarker = piece_instance.connection_markers.pick_random()
	_align_piece_to_marker(piece_instance, previous_marker, new_marker)
	
	#Make sure just used markers arent free
	free_markers.erase(new_marker)
	free_markers.erase(previous_marker)
	
	var piece_markers : Array[ConnectionMarker] = piece_instance.connection_markers
	for marker in piece_markers:
		if marker == new_marker: continue # Don't add marker that was just use
		if free_markers.has(marker): continue # if marker already there dont add it again
		
		free_markers.append(marker)
	
	await get_tree().physics_frame
	
	# Start placing new pieces at the newly added markers
	_process_free_markers()


func _process_free_markers():
	if free_markers.is_empty(): 
		generation_finished.emit()
		return
	
	var marker_to_place : ConnectionMarker = free_markers.pick_random()
	free_markers.erase(marker_to_place)  # Remove the marker from free_markers after use
	var chosen_piece = _get_random_hallway_piece()
	
	current_depth += 1
	_place_piece_at_marker(marker_to_place, chosen_piece)


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


func _place_blockage_at_marker(marker : ConnectionMarker):
	var blockage_instance = HALLWAY_BLOCKAGE.instantiate()
	hallways_holder.add_child(blockage_instance, true)
	blockage_instance.set_owner(self.get_parent())
	
	blockage_instance.global_transform = marker.global_transform


func _check_if_looped(current_marker : ConnectionMarker) -> bool:
	var tolerance = 0.01
	
	for marker in free_markers:
		if marker == current_marker: continue
		
		if marker.global_position.distance_to(current_marker.global_position) < tolerance: 
			
			free_markers.erase(current_marker)
			free_markers.erase(marker)
			
			return true
	
	return false


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

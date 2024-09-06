extends Interactable
class_name Door

enum LOCKED_STATES {
	UNLOCKED,
	LOCKED,
	LOCKED_FROM_INSIDE,
}
@export var locked_state : LOCKED_STATES = LOCKED_STATES.UNLOCKED
@export var unlocked_messages : Array[String] = ["The door is unlocked."]
@export var locked_messages : Array[String] = ["The door is locked.", "I can't open this door."]
@export var locked_from_inside_messages : Array[String] = ["The door is locked from the other side."]

@export_group("Required")
@export var entry_point : Marker3D
@export var exit_point : Marker3D
@export var interact_camera : Camera3D


func _ready():
	assert(entry_point, "No Entry Point")
	assert(exit_point, "No Exit Point")
	assert(interact_camera, "No Interact Camera")


func interact(interactor : CharacterBody3D) -> String:
	if not can_interact: return super(interactor)
	
	match locked_state:
		LOCKED_STATES.UNLOCKED:
			_open_door(interactor)
			return unlocked_messages[randi() % unlocked_messages.size()]
		
		LOCKED_STATES.LOCKED:
			return locked_messages[randi() % locked_messages.size()]
		
		LOCKED_STATES.LOCKED_FROM_INSIDE:
			return locked_from_inside_messages[randi() % locked_from_inside_messages.size()]
		
		_:
			return super(interactor)
	


func _open_door(interactor : CharacterBody3D):
	var dist_to_entry := interactor.global_position.distance_to(entry_point.global_position)
	var dist_to_exit := interactor.global_position.distance_to(exit_point.global_position)
	
	var on_outside := true if dist_to_entry <= dist_to_exit else false
	
	interactor.global_position = exit_point.global_position if on_outside else entry_point.global_position

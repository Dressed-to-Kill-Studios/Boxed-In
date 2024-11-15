extends CharacterBody3D
class_name Player

@onready var raycast = $RayCast3D

var turn_speed : float = 3.0
var mouse_sens : float = 0.3

#Movement
var input_locked : bool = false
var can_move : bool = true

enum MOVEMENT_STATES {
	WALKING,
	SPRINTING,
	AIMING,
}
var current_movement : int = MOVEMENT_STATES.WALKING

const ACCELERATION : float = 10.0
const SPEED : float = 5.0
const SPRINT_SPEED : float = 7.5


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * mouse_sens
	
	if Input.is_action_just_pressed("options"): 
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	
	if Input.is_action_just_pressed("interact"):
		interacting()
	
	if Input.is_action_just_pressed("inventory"):
		%Inventory.visible = !%Inventory.visible


func _physics_process(delta):
	handle_movement(delta)


func handle_movement(delta : float):
	var input_dir : float = Input.get_axis("forward", "backward")
	var direction := (transform.basis * Vector3(0, 0, input_dir))
	
	current_movement = MOVEMENT_STATES.WALKING if Input.is_action_pressed("sprint") \
						and input_dir <= -0.5 else MOVEMENT_STATES.SPRINTING
	
	#Apply rotation
	rotation_degrees.y -= Input.get_axis("turn_left", "turn_right") * turn_speed
	
	#Calulate Movement
	var wish_velocity := direction * SPEED if can_move else Vector3.ZERO
	wish_velocity = direction * SPRINT_SPEED if current_movement == MOVEMENT_STATES.SPRINTING else wish_velocity
	
	velocity.x = velocity.lerp(wish_velocity, ACCELERATION * delta).x
	velocity.z = velocity.lerp(wish_velocity, ACCELERATION * delta).z
	
	move_and_slide()


func interacting():
	var interact_body : Interactable = raycast.get_collider() 
	
	if interact_body: print(interact_body.interact(self))

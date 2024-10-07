extends StaticBody3D
class_name Interactable

@export var can_interact : bool = true
@export var can_interact_messages : Array[String] = ["I can interact with this."]
@export var cant_interact_messages : Array[String] = ["I can't interact with this"]


func interact(interactor : CharacterBody3D) -> String:
	var interact_msg : String = can_interact_messages[randi() % can_interact_messages.size()]
	
	interact_msg = cant_interact_messages[randi() % cant_interact_messages.size()] if not can_interact else interact_msg
	
	return interact_msg

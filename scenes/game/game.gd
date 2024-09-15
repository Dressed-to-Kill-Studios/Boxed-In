extends Node

#Difficulty
enum DIFFICULTIES {
	EASY,
	NORMAL,
	HARD,
}

var current_difficulty : DIFFICULTIES

@onready var facility = %Facility


func _init(_difficulty : DIFFICULTIES = DIFFICULTIES.NORMAL):
	current_difficulty = _difficulty

func _ready():
	pass #if not Engine.is_editor_hint(): facility.generate_facility()

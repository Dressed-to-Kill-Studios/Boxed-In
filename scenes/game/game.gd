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
	if Engine.is_editor_hint(): return
	
	AudioManager.play(AudioManager.AUDIO_THEMES.SAFE_ROOM, 10.0)
	facility.generate_facility()

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
	
	AudioManager.play(AudioManager.AUDIO_THEMES.TITLE, 2.5)
	facility.generate_facility()


func _process(delta):
	if Input.is_action_just_released("ui_accept"): AudioManager.play(AudioManager.AUDIO_THEMES.CHASE)

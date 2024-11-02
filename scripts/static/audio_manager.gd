extends Node

enum AUDIO_THEMES {
	TITLE,
	SAFE_ROOM,
	AMBIENCE,
	CHASE,
	GAME_OVER
}

const AUDIO = {
	"title" : [
		preload("res://assets/audio/music/title/Echo Stream.wav"),
		preload("res://assets/audio/music/title/Purple Gaze.wav"),
		preload("res://assets/audio/music/title/Red Gaze.wav"),
	],
	"safe_room" : [
		preload("res://assets/audio/music/safe_room/Respite.wav")
	],
	"ambience" : [
		preload("res://assets/audio/ambience/Ambience_1.mp3"),
		preload("res://assets/audio/ambience/Ambience_2.mp3"),
		preload("res://assets/audio/ambience/Ambience_3.mp3"),
		preload("res://assets/audio/ambience/Ambience_4.mp3"),
		preload("res://assets/audio/ambience/Ambience_5.mp3"),
	],
	"chase" : [],
	"game_over" : [],
}

var current_audio : AudioStreamPlayer


func _ready() -> void:
	pass


func play(audio_theme : AUDIO_THEMES) -> void:
	if current_audio: current_audio.queue_free()
	
	current_audio = AudioStreamPlayer.new()
	add_child(current_audio)
	
	var chosen_theme : Array = AUDIO.get(AUDIO.keys()[audio_theme])
	
	current_audio.stream = chosen_theme[randi() % chosen_theme.size()]
	current_audio.play()

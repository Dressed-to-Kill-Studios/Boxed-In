extends Node


signal theme_changed(old_theme : AUDIO_THEMES, new_theme : AUDIO_THEMES)

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
	"chase" : [
		preload("res://assets/audio/music/chase/Vision.wav")
	],
	"game_over" : [
		preload("res://assets/audio/music/game_over/Channel.wav"),
		preload("res://assets/audio/music/game_over/Memory.wav"),
		preload("res://assets/audio/music/game_over/Ruin.wav"),
	],
}

var current_theme : AUDIO_THEMES
var current_player : AudioStreamPlayer
var current_volume : float = 0.0 #0 (silent) to 1 (full volume)


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if current_player: current_player.volume_db = linear_to_db(current_volume)


func change_theme(audio_theme : AUDIO_THEMES) -> void:
	theme_changed.emit(current_theme, audio_theme)
	
	current_theme = audio_theme


func play(audio_theme : AUDIO_THEMES, fade : float = 0.0) -> void:
	if current_player: current_player.queue_free()
	
	current_player = AudioStreamPlayer.new()
	current_player.bus = "Music"
	add_child(current_player)
	
	change_theme(audio_theme)
	var chosen_theme : Array = AUDIO.get(AUDIO.keys()[current_theme])
	
	current_player.stream = chosen_theme[randi() % chosen_theme.size()]
	current_player.play()
	
	if fade <= 0.0: return
	
	current_player.volume_db = -INF
	
	var tween := create_tween()
	tween.tween_property(self, "current_volume", 1.0, fade)

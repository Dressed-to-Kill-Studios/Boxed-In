extends Node


signal theme_changed(old_theme : AUDIO_THEMES, new_theme : AUDIO_THEMES)
signal started_playing(theme : AUDIO_THEMES)
signal stopped_playing(theme : AUDIO_THEMES)
signal finished_playing(theme : AUDIO_THEMES)

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
		preload("res://assets/audio/ambience/Ambience_6.mp3"),
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
const MIN_LOOP_WAIT_TIME_SECONDS : float = 150.0
const MAX_LOOP_WAIT_TIME_SECONDS : float = 300.0

var current_theme : AUDIO_THEMES
var current_player : AudioStreamPlayer
var current_volume : float = 0.0 #0.0 (silent) to 1.0 (full volume)


func _ready():
	pass


func _physics_process(delta: float):
	if current_player: current_player.volume_db = linear_to_db(current_volume)


func change_theme(audio_theme : AUDIO_THEMES):
	theme_changed.emit(current_theme, audio_theme)
	
	current_theme = audio_theme


func play(audio_theme : AUDIO_THEMES, fade : float = 0.0, loop_track : bool = true, excluded_track : Resource = null):
	#Create new audio player
	if current_player: #If currently playing something, wait for player to stop
		stop()
		await stopped_playing
	
	_create_new_player()
	
	#Get tracks from theme
	change_theme(audio_theme)
	var chosen_theme : Array = AUDIO.get(AUDIO.keys()[current_theme])
	
	#Start playing
	var chosen_track : Resource
	while true: #Check if chosen track is excluded track
		chosen_track = chosen_theme[randi() % chosen_theme.size()]
		
		if chosen_track != excluded_track: break
	
	current_player.stream = chosen_track
	current_player.play()
	started_playing.emit(current_theme)
	
	#Fade in audio
	current_player.volume_db = -INF
	
	var tween := create_tween()
	tween.tween_property(self, "current_volume", 1.0, fade)
	
	if not loop_track:
		await finished_playing
		await get_tree().create_timer(randf_range(MIN_LOOP_WAIT_TIME_SECONDS, MAX_LOOP_WAIT_TIME_SECONDS)).timeout
		play(current_theme, fade, false, current_player.stream)


func stop(fade : float = 2.0):
	#Fade out audio
	var tween := create_tween()
	tween.tween_property(self, "current_volume", 0.0, fade)
	
	await tween.finished
	
	#Clear player
	if current_player: current_player.queue_free()
	current_player = null
	stopped_playing.emit(current_theme)
	


func _create_new_player():
	current_player = AudioStreamPlayer.new()
	current_player.bus = "Music"
	add_child(current_player)
	
	current_player.finished.connect(_player_finished)


func _player_finished():
	finished_playing.emit(current_theme)

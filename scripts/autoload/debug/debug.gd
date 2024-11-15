extends Node

#Signals
signal debug_messege

#Constants
const debug_panel_path = preload("res://scenes/debug/debug_panel.tscn")

#
var debug_on : bool = false : set = _set_debug

#Refrences
var debug_panel : Control

#Commands
var DEBUG_COMMAND := DebugCommand.new(\
	"debug", \
	"This command enables or disables the debug commands.", \
	_set_debug, \
	[ArgumentFormat.new("enable", TYPE_BOOL, true)])

var TEST_COMMAND := DebugCommand.new(\
	"_test", \
	"This command is for testing purposes.", \
	func(): send_debug_messege("Test Command fired."))

var PING_PONG_COMMAND := DebugCommand.new(\
	"_ping", \
	"This command responds back.", \
	func(): send_debug_messege("Pong!"))

var REPEAT_COMMAND := DebugCommand.new(\
	"_repeat", \
	"This command repeats back what was said.", \
	func(text : String): send_debug_messege(text), \
	[ArgumentFormat.new("text", TYPE_STRING)])

var HELP_COMMAND := DebugCommand.new(\
	"help", \
	"This command shows all usable commands.", \
	help_command)

var QUIT_COMMAND := DebugCommand.new(\
	"quit", \
	"This command closes the game.", \
	func(): send_debug_messege("Quitting game."); await get_tree().create_timer(0.5).timeout; get_tree().quit())

var PLAY_SOUNDTRACK := DebugCommand.new(\
	"play_soundtrack", \
	"Play soundtrack from theme.", \
	func(theme : int, fade : float): AudioManager.play(theme, fade); send_debug_messege("Playing theme %s." % theme), \
	[ArgumentFormat.new("theme", TYPE_INT), ArgumentFormat.new("fade", TYPE_FLOAT, 0.0)])

var STOP_SOUNDTRACK := DebugCommand.new(\
	"stop_soundtrack", \
	"Stop current soundtrack.", \
	func(fade : float): AudioManager.stop(fade); send_debug_messege("Stopped current soundtrack."), \
	[ArgumentFormat.new("fade", TYPE_FLOAT)])

#Allowed Commands
var command_list : Array[DebugCommand] = [
	DEBUG_COMMAND,
	
	TEST_COMMAND,
	PING_PONG_COMMAND,
	REPEAT_COMMAND,
	
	HELP_COMMAND,
	QUIT_COMMAND,
	
	#Music
	PLAY_SOUNDTRACK,
	STOP_SOUNDTRACK,
]


func _ready():
	#Add Debug panel
	debug_panel = debug_panel_path.instantiate()
	debug_panel.hide()
	add_child(debug_panel)


func _set_debug(value):
	debug_on = value
	
	send_debug_messege("Debug commands set to %s." % debug_on)


func command_evaluation(command_id : String, arguments : Array):
	var command : DebugCommand
	
	for cmd in command_list: #Convert ID to Command
		var cmd_name = cmd.id
		
		if cmd.id.begins_with("_"): cmd_name = cmd.id.substr(1, cmd.id.length() - 1)
		
		if cmd_name == command_id.to_lower():
			command = cmd
			break
	
	if not debug_on and command != DEBUG_COMMAND: #Debug commands on check
		send_debug_messege("Debug commands are not turned on.")
		return
	
	if not command: #Valid Command Check
		send_debug_messege("Command not found.")
		return
	
	
	#Arguments Check
	var required_arguments : int = 0
	
	for arg in command.format:
		if arg.default_value == null: required_arguments += 1
	
	if arguments.size() < required_arguments: 
		send_debug_messege('Not enough arguments given for the "%s" command. Expected at least %s.' % [command_id.capitalize(), required_arguments])
		return
		
	if arguments.size() > command.format.size(): #Too many args
		send_debug_messege('Too many arguments given for the "%s" command. Expected at most %s.' % [command_id.capitalize(), command.format.size()])
		return
	
	
	#Convert Arguments to Type
	var passing_arguments : Array = []
	
	for n in range(command.format.size()):
		var current_arg : ArgumentFormat = command.format[n]
		
		if arguments.size() < n + 1: 
			passing_arguments.append(current_arg.default_value)
			continue
		
		match current_arg.argument_type:
			TYPE_BOOL:
				if arguments[n].to_lower() == "true": passing_arguments.append(true)
				elif arguments[n].to_lower() == "false": passing_arguments.append(false)
				else:
					_send_incorrect_argument_messege(n + 1, typeof(arguments[n]), TYPE_BOOL)
					return
			
			TYPE_FLOAT:
				if not arguments[n].is_valid_float():
					_send_incorrect_argument_messege(n + 1, typeof(arguments[n]), TYPE_FLOAT)
					return
				
				passing_arguments.append(float(arguments[n]))
			
			TYPE_INT:
				if not arguments[n].is_valid_int():
					_send_incorrect_argument_messege(n + 1, typeof(arguments[n]), TYPE_INT)
					return
				
				passing_arguments.append(float(arguments[n]))
			
			TYPE_STRING:
				passing_arguments.append(arguments[n])
	
	command.invoke(passing_arguments)


func help_command():
	send_debug_messege("Commands:")
	
	for command in command_list:
		var arg_text : Array[String] = []
		
		for arg in command.format:
			var single_arg_text : String = ""
			
			single_arg_text = _type_to_string(arg.argument_type)
			single_arg_text = "%s = %s %s" % [arg.argument_name, arg.default_value, single_arg_text] if arg.default_value != null\
				else "%s %s" % [arg.argument_name, single_arg_text]
			single_arg_text = "[lb]%s[rb]" % single_arg_text if arg.default_value else "(%s)" % single_arg_text
			arg_text.append(single_arg_text)
		
		if not command.id.begins_with("_"): \
		send_debug_messege("[b]>%s:[/b] %s [i]Parameters:[/i] %s" % [
			command.id.to_upper(), 
			command.description, 
			", ".join(arg_text) if not arg_text.is_empty() else "None"])


func send_debug_messege(text : String):
	debug_messege.emit(text)


func _send_incorrect_argument_messege(arg_pos : int, recieved_arg_type : int, expected_arg_type : int):
	var recieved_text : String = str(recieved_arg_type)
	var expected_text : String = str(expected_arg_type)
	
	recieved_text = _type_to_string(recieved_arg_type)
	expected_text = _type_to_string(expected_arg_type)
	
	send_debug_messege("Incorrect argument type (Argument %s: recieved %s, expected %s)" %\
	[arg_pos, recieved_text, expected_text])


func _type_to_string(type : int) -> String:
	match type:
		TYPE_BOOL:
			return "[color=red]<bool>[/color]"
		
		TYPE_INT:
			return "[color=darkblue]<int>[/color]"
		
		TYPE_FLOAT:
			return "[color=aqua]<float>[/color]"
		
		TYPE_STRING:
			return "[color=lawngreen]<string>[/color]"
		
		_:
			return ""


class ArgumentFormat:
	var argument_name : String
	var argument_type : int
	var default_value 
	
	
	func _init(_name : String, _type : int, _default = null):
		argument_name = _name
		argument_type = _type
		default_value = _default


class DebugCommand:
	var id : String
	var description : String
	var command : Callable
	var format : Array[ArgumentFormat]
	
	
	func _init(_id : String, _description : String, _command : Callable, _format : Array[ArgumentFormat] = []):
		id = _id
		description = _description
		command = _command
		format = _format
	
	func invoke(args = []):
		command.callv(args)

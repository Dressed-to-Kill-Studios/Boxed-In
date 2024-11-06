extends Node

#Signals
signal debug_messege

var debug_on : bool = false : set = _set_debug

#Refrences
var player : Player = null

#Commands
var DEBUG_COMMAND : DebugCommand = DebugCommand.new(\
	"debug", \
	"This command enables or disables the debug commands.", \
	_set_debug, \
	[ArgumentFormat.new("enable", TYPE_BOOL, true)])

var TEST_COMMAND : DebugCommand = DebugCommand.new(\
	"_test", \
	"This command is for testing purposes.", \
	func(): send_debug_messege("Test Command fired.") ; pass)
var PING_PONG_COMMAND : DebugCommand = DebugCommand.new(\
	"_ping", \
	"This command responds back.", \
	func(): send_debug_messege("Pong!"))
var REPEAT_COMMAND : DebugCommand = DebugCommand.new(\
	"_repeat", \
	"This command repeats back what was said.", \
	func(text : String): send_debug_messege(text), \
	[ArgumentFormat.new("text", TYPE_STRING)])

var HELP_COMMAND : DebugCommand = DebugCommand.new(\
	"help", \
	"This command shows all usable commands.", \
	help_command)

#Allowed Commands
var command_list : Array[DebugCommand] = [
	DEBUG_COMMAND,
	
	TEST_COMMAND,
	PING_PONG_COMMAND,
	REPEAT_COMMAND,
	
	HELP_COMMAND,
]


func _ready():
	pass


func _set_debug(value):
	debug_on = value
	
	send_debug_messege("Debug commands set to %s" % debug_on)


func command_evaluation(command_id : String, arguments : Array):
	var command : DebugCommand
	
	for cmd in command_list: #Convert ID to Command
		var cmd_name = cmd.id
		
		if cmd.id.begins_with("_"): cmd_name = cmd.id.substr(1, cmd.id.length() - 1)
		
		if cmd_name == command_id.to_lower():
			command = cmd
			break
	
	if not debug_on and command != DEBUG_COMMAND:#Debug commands on check
		send_debug_messege("Debug commands are not on")
		return
	
	if not command: #Valid Command Check
		send_debug_messege("Command not found")
		return
	
	
	#Arguments Check
	var required_arguments : int = 0
	
	for arg in command.format:
		if arg.default_value == null: required_arguments += 1
	
	if arguments.size() < required_arguments: 
		send_debug_messege('Not enough arguments given for the "%s" command' % command_id.capitalize())
		return
		
	if arguments.size() > command.format.size(): #Too many args
		send_debug_messege('Too many arguments given for the "%s" command' % command_id.capitalize())
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
					send_debug_messege("Incorrect argument type (argument %s)" % [n + 1])
					return
			
			TYPE_FLOAT:
				passing_arguments.append(float(arguments[n]))
			
			TYPE_INT:
				passing_arguments.append(int(arguments[n]))
			
			TYPE_STRING:
				passing_arguments.append(arguments[n])
	
	command.invoke(passing_arguments)


func help_command():
	send_debug_messege("Commands:")
	
	for command in command_list:
		var arg_text : Array[String] = []
		
		for arg in command.format:
			var single_arg_text : String = ""
			
			match arg.argument_type:
				TYPE_BOOL:
					single_arg_text = "[color=red]<bool>[/color]"
				
				TYPE_INT:
					single_arg_text = "[color=darkblue]<int>[/color]"
				
				TYPE_FLOAT:
					single_arg_text = "[color=aqua]<float>[/color]"
				
				TYPE_STRING:
					single_arg_text = "[color=lawngreen]<string>[/color]"
			
			single_arg_text = "%s = %s %s" % [arg.argument_name, arg.default_value, single_arg_text] if arg.default_value \
				else "%s%s" % [arg.argument_name, single_arg_text]
			single_arg_text = "[%s]" % single_arg_text if arg.default_value else "(%s)" % single_arg_text
			arg_text.append(single_arg_text)
		
		if not command.id.begins_with("_"): \
		send_debug_messege("[b]>%s:[/b] %s [i]Parameters:[/i] %s" % [
			command.id.to_upper(), 
			command.description, 
			", ".join(arg_text) if not arg_text.is_empty() else "None"])


func send_debug_messege(text : String):
	debug_messege.emit(text)


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

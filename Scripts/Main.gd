extends Node

onready var console = $HUD/Console
onready var output = $HUD/OutputContainer/Output

var codeEnd

var variables = {} 
var constVariables = {
	"true": true,
	"false": false,
}

func _ready():
	pass

func process_assignment(line):
	var varName = line.split(" = ")[0]
	var expression = line.split(" = ")[1]
	var expressionSections = expression.split(" ")
	
	if expressionSections.size() == 1:
		if expression.is_valid_integer():
			variables[varName] = expression.to_int()
		elif expression.is_valid_float():
			variables[varName] = expression.to_float()
		elif expression[0] == "\"":
			variables[varName] = expression
	else:
		pass
	
func calculate_math_expression(expression):
	pass

	
func crash(error, line):
	output.newline()
	output.add_text("Error: " + error + ". For line: " + str(line))

func create_variable(line):
	var varName = line.split(" ")[1]
	for i in variables:
		if i == varName:
			crash("variable already exists", line)
	variables[varName] = null
	if line.split(" ")[2] == "=":
		var assignmentLine = line.replace("var ", "")
		process_assignment(assignmentLine)
		
func get_condition_result(expression):
	var sections = expression.split(" ")
	var members = []
	
	var i = 0
	while i < sections.size()-1:
		if variables.has(sections[i]) or constVariables.has(sections[i]): 
			members.append(sections[i])
			i += 1
		else:
			match sections[i]:
				"==":
					if i+1 > sections.size():
						pass #Erro
					if sections[i-1] == sections[i+1]:
						members.append(true)
					else:
						members.append(false)
					
					i += 2
				"!=":
					if i+1 > sections.size():
						pass #Erro
					if sections[i-1] != sections[i+1]:
						members.append(true)
					else:
						members.append(false)
						
					i += 2
				">":
					if i+1 > sections.size():
						pass #Erro
					if sections[i-1] > sections[i+1]:
						members.append(true)
					else:
						members.append(false)
						
					i += 2
				"<":
					if i+1 > sections.size():
						pass #Erro
					if sections[i-1] < sections[i+1]:
						members.append(true)
					else:
							members.append(false)
							
					i += 2
				">=":
					if i+1 > sections.size():
						pass #Erro
					if sections[i-1] >= sections[i+1]:
						members.append(true)
					else:
						members.append(false)
						
					i += 2
				"<=":
					if i+1 > sections.size():
						pass #Erro
					if sections[i-1] <= sections[i+1]:
						members.append(true)
					else:
						members.append(false)
						
					i += 2
				"and":
					if i+1 > sections.size():
						pass #Erro
					members.append("and")
					i += 1
				"or":
					if i+1 > sections.size():
						pass #Erro
					members.append("or")
					i += 1
				_:
					i +=1
	
	while members.size() != 1:
		if members[1] == "and":
			if members[0] == true and members[2] == true:
				members.pop_front()
				members.pop_front()
				members.pop_front()
				members.push_front(true)
			else:
				members.pop_front()
				members.pop_front()
				members.pop_front()
				members.push_front(false)
		elif members[1] == "or":
			if members[0] == false and members[2] == false:
				members.pop_front()
				members.pop_front()
				members.pop_front()
				members.push_front(false)
			else:
				members.pop_front()
				members.pop_front()
				members.pop_front()
				members.push_front(true)
		else:
			pass #Erro		
	return members[0]
	
func get_end_bracket(startIndex):
	for i in range(startIndex, codeEnd):
		if console.get_line(i) == "}":
			return i + 1
			
	crash("Expecting } ", startIndex)

func get_chain_end_line(startIndex):
	for i in range(startIndex, codeEnd):
		if console.get_line(i)[0] == "":
			pass
		elif console.get_line(i).split(" ")[0] == "elif" or console.get_line(i).split(" ")[0] == "else":
			var newIndex = get_end_bracket(i)
			return get_chain_end_line(newIndex)
		else:
			return i

func look_for_else(startIndex):
	for i in range(startIndex, codeEnd):
		if console.get_line(i) == "":
			pass
		elif console.get_line(i).split(" ")[0] == "elif" or console.get_line(i).split(" ")[0] == "else":
			return i
		else:
			return -1

func handle_condition(expression, lineIndex, stopIndex):
	var runCondition = get_condition_result(expression)
	
	var stopConditionIndex = get_end_bracket(lineIndex)
	
	if runCondition:
		run_line(lineIndex + 1, stopConditionIndex)
		var endChainIndex = get_chain_end_line(stopConditionIndex)
		run_line(endChainIndex, stopIndex)
	else:
		var nextConditionIndex = look_for_else(stopConditionIndex)
		if nextConditionIndex == null or nextConditionIndex == -1:
			run_line(stopConditionIndex, stopIndex)
		elif console.get_line(nextConditionIndex).split(" ")[0] == "elif":
			var newExpression = console.get_line(nextConditionIndex).replace("elif ", "").replace(" {","")
			handle_condition(newExpression, stopConditionIndex, stopIndex)
		else:
			run_line(stopConditionIndex, stopIndex)

func run_line(lineIndex, stopIndex):
	if lineIndex == null or lineIndex > stopIndex:
		pass
	elif console.get_line(lineIndex) == "" or console.get_line(lineIndex) == "}":
		run_line(lineIndex+1, stopIndex)
	else:
		var line = console.get_line(lineIndex)
		
		if line[0] == "	":
			line = line.replace("	", "")
		
		var sections = line.split(" ")
		
		if sections[0] == "var":
			create_variable(line)
			run_line(lineIndex+1, stopIndex)
			
		elif sections[1] == "=":
			process_assignment(line)
			run_line(lineIndex+1, stopIndex)
			
		elif sections[0] == "print":
			output.newline()
			output.add_text(str(variables[sections[1]]))
			run_line(lineIndex+1, stopIndex)
			
		elif sections[0] == "if" or sections[0] == "elif"  or sections[0] == "else":
			var expression = line.replace("if ", "").replace("elif ", "").replace("else ", "").replace(" {","")
			handle_condition(expression, lineIndex, stopIndex)
	
	
func _on_RunButton_pressed():
	variables.clear()
	codeEnd = console.get_line_count()
	run_line(0, codeEnd)

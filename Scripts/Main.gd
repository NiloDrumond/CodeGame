extends Node

onready var console = $HUD/Console
onready var variablesList = $HUD/VariablesContainer/Variables
onready var output = $HUD/OutputContainer/Output
onready var simulation = $Simulation

var codeEnd

var variables = {} 
var constVariables = {
	"true": true,
	"false": false,
}

var calcPriorities = {
	"%" : 2,
	"*" : 1,
	"/" : 1,
	"+" : 0,
	"-" : 0
}

var objectsFunctions = []

var objects = []
var objGetVariables = []
var objSetVariables = []
var simGetVariables
var simSetVariables

var builtFunctions = {
	"print" : funcref(self, "print_function")
	
}

func print_variables_list():
	if !simGetVariables.empty():
		variablesList.add_text("Simulation Variables:\n")
		for i in simGetVariables.keys():
			variablesList.add_text(" " + i + "\n")
	if objects.size() > 0:
		for i in range(objects.size()):
			if !objGetVariables[i].empty():
				variablesList.add_text(objects[i].name + ":\n")
				for j in objGetVariables[i].keys():
					variablesList.add_text(" " + j + "\n")

var functions = {}

func _on_simulation_end(status):
	if status:
		print("great sucess")
	else:
		print("you failed")

func _ready():
	create_simulation()
	print_variables_list()

func create_simulation():
	simulation.connect("simulationEnd", self, "_on_simulation_end")
	
	simGetVariables = simulation.get_get_variables()
	simSetVariables = simulation.get_set_variables()
	
	objects = simulation.get_objects()
	
	for o in range(objects.size()):
		objectsFunctions.append(objects[o].get_functions())
		objSetVariables.append(objects[o].get_set_variables())
		objGetVariables.append(objects[o].get_get_variables())

func print_function(arguments):
	var printContent = arguments[0]
	output.newline()
	if variables.has(printContent):
		output.add_text(str(variables[printContent]))
	elif constVariables.has(printContent):
		output.add_text(str(constVariables[printContent]))
	else:
		output.add_text(str(printContent))
	

func create_calc_tree(expression, lineIndex):
	if expression == "" or expression == null:
		return null
	
	var calc = [null, null, null]
	var topPrio = 4
	var topPrioPos = null
	var c
	var par = 0
	var parTopPrio = 4
	var parTopPrioPos = null
	for i in range(expression.length()):
		c = expression[i]
		if c == "(":
			par += 1
		elif c == ")":
			par -= 1
		if calcPriorities.has(c):
			if par == 0 and calcPriorities[c] < topPrio:
				topPrioPos = i
				topPrio = calcPriorities[c]
			elif calcPriorities[c] < parTopPrio:
				parTopPrio = calcPriorities[c]
				parTopPrioPos = i
				
			
	if topPrioPos != null:
		calc[0] = expression[topPrioPos]
		calc[1] = create_calc_tree(expression.substr(0, topPrioPos), lineIndex)
		calc[2] = create_calc_tree(expression.substr(topPrioPos+1, expression.length() - (topPrioPos+1)), lineIndex)
		return calc
	elif parTopPrioPos != null:
		calc[0] = expression[parTopPrioPos]
		calc[1] = create_calc_tree(expression.substr(0, parTopPrioPos), lineIndex)
		calc[2] = create_calc_tree(expression.substr(parTopPrioPos+1, expression.length() - (parTopPrioPos+1)), lineIndex)
		return calc
	else:
		
		expression = expression.replace("(", "").replace(")", "")
		if expression.is_valid_integer():
			calc[0] = expression.to_int()
		elif expression.is_valid_float():
			calc[0] = expression.to_float()
			
		else:
			if string_has(expression, "."):
				var objName = expression.split(".")[0]
				var objVar = expression.split(".")[1]
				
				if objName == "Sim":
					if !simGetVariables.empty() and simGetVariables.has(objVar):
						calc[0] = simGetVariables[objVar].call_func()
					else:
						crash("invalid simulation variable", lineIndex)
				
				else:
					var objIndex = null
					for i in range(objects.size()):
						if objects[i].name == objName:
							objIndex = i
							break
					if objIndex != null and !objGetVariables[objIndex].empty() and objGetVariables[objIndex].has(objVar):
						calc[0] = objGetVariables[objIndex][objVar].call_func()
					else:
						crash("invalid object variable", lineIndex)
						
			else:
				if !constVariables.empty() and constVariables.has(expression):
					calc[0] = constVariables[expression]
				elif !variables.empty() and variables.has(expression):
					calc[0] = variables[expression]
				else:
					crash("unexpected variable", lineIndex)
			
		calc[1] = null
		calc[2] = null
		return calc
	
func calculate_tree(node):
	if node != null and node[0] != null:
		match node[0]:
			"%":
				return calculate_tree(node[1]) % calculate_tree(node[2])
			"*":
				return calculate_tree(node[1]) * calculate_tree(node[2])
			"/":
				var res1 = calculate_tree(node[1])
				var res2 = calculate_tree(node[2])
				if typeof(res1) == TYPE_INT and typeof(res2) == TYPE_INT:
					if res1 % res2 != 0:
						return float(res1) / float(res2)
					else:
						return res1 / res2
				else:
					return res1 / res2
			"+":
				return calculate_tree(node[1]) + calculate_tree(node[2])
			"-":
				return calculate_tree(node[1]) - calculate_tree(node[2])
			_:
				return node[0]
			
func calculate_expression(expression, lineIndex):
	
	var expressionSections = expression.split(" ")

	if expressionSections.size() == 1:
		var value = expressionSections[0]
		if value.is_valid_integer():
			return value.to_int()
		elif value.is_valid_float():
			return value.to_float()
		else:
			var isObject = false
			var objName
			var objVar
			if string_has(value, "."):
				objName =  value.split(".")[0] 
				objVar = value.split(".")[1]
				isObject = true
			
			if isObject:
				if objName == "Sim":
					if !simGetVariables.empty() and simGetVariables.has(objVar):
						return simGetVariables[objVar].call_func()
					else:
						crash("invalid simulation variable", lineIndex)
				else:
					var object
					var objectIndex
					
					for o in range(objects.size()):
						if objects[o].name == objName:
							object = objects[o]
							objectIndex = o
							break
					if !objGetVariables.empty() and objGetVariables.has(objVar):
						return objGetVariables[objVar].call_func()
					else:
						crash("invalid object variable", lineIndex)
					
	else:
		expression = expression.replace(" ", "")
		var calcTree = create_calc_tree(expression, lineIndex)
		return calculate_tree(calcTree)
				
func process_assignment(line, lineIndex):
	var varName = line.split(" = ")[0]
	var varVariable = null
	var isObject = false
	
	if string_has(varName, "."):
		varVariable = varName.split(".")[1]
		varName = varName.split(".")[0]
		isObject = true
		
	var expression = line.split(" = ")[1]
	
	if isObject:
		if varName == "Sim":
			if !simSetVariables.empty() and simSetVariables.has(varName):
				simSetVariables[varVariable].call_func(calculate_expression(expression, lineIndex))
		else:
			var object
			var objectIndex
			#Error: no object found
			for o in range(objects.size()):
				if objects[o].name == varName:
					object = objects[o]
					objectIndex = o
					break
			
			if !objSetVariables[objectIndex].empty() and objSetVariables[objectIndex].has(varVariable):
				objSetVariables[objectIndex][varVariable].call_func(calculate_expression(expression, lineIndex))
	else:
		if !constVariables.empty() and constVariables.has(varName):
			crash("cant modify constant variables", lineIndex)
		elif !variables.empty() and variables.has(varName):
			variables[varName] = calculate_expression(expression, lineIndex)
		else:
			crash("unexpected variable", lineIndex)


func crash(error, line):
	output.newline()
	output.add_text("Error: " + error + ". For line: " + str(line))
	print("Error: " + error + ". For line: " + str(line))

func create_variable(line, lineIndex):
	var varName = line.split(" ", false, 2)[1]
	for i in variables:
		if i == varName:
			crash("variable already exists", line)
	variables[varName] = null
	if line.split(" ")[2] == "=":
		var assignmentLine = line.replace("var ", "")
		process_assignment(assignmentLine, lineIndex)
		
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
			run_line(stopConditionIndex+1, stopIndex)

func read_function(expression, lineIndex):
	var f = expression.split("(", true, 1)[0]
	var arguments = expression.split("(", true, 1)[1].rsplit(")", true, 1)[0].split(",")
	if builtFunctions.has(f):
		return builtFunctions[f].call_func(arguments)
	else:
		crash("invalid function", lineIndex)
	
func handle_loop(lineIndex, stopIndex):
	var line = console.get_line(lineIndex)
	var content = line.split(" ")[1]
	var loopEnd = get_end_bracket(lineIndex)
	var iterations
	if variables.has(content):
		iterations = variables[content]
	elif constVariables.has(content):
		iterations = constVariables[content]
	elif content.is_valid_integer():
		iterations = content
	else:
		crash("invalid loop argument", lineIndex)
		
	for i in range(iterations):
		run_line(lineIndex+1, loopEnd)
		
	run_line(loopEnd, stopIndex)
		
func run_line(lineIndex, stopIndex):

	if lineIndex == null or lineIndex > stopIndex:
		pass
	elif console.get_line(lineIndex) == "" or console.get_line(lineIndex) == "}":
		run_line(lineIndex+1, stopIndex)
	else:
		var line = console.get_line(lineIndex)
		
		if line[0] == "	":
			line = line.replace("	", "")
		
		var sections = line.split(" ", false)
		
		if sections[0] == "var":
			create_variable(line, lineIndex)
			run_line(lineIndex+1, stopIndex)
			
		elif sections.size() > 1 and sections[1] == "=":
			process_assignment(line, lineIndex)
			run_line(lineIndex+1, stopIndex)
			
		elif sections[0] == "if" or sections[0] == "elif":
			var expression = line.replace("if ", "").replace("elif ", "").replace("else ", "").replace(" {","")
			handle_condition(expression, lineIndex, stopIndex)
		
		elif sections[0] == "loop":
			handle_loop(lineIndex, stopIndex)
			
		else:
			for f in builtFunctions:
				if sections[0].begins_with(f):
					read_function(line, lineIndex)
					run_line(lineIndex+1, stopIndex)
			for f in functions:
				if sections[0].begins_with(f):
					read_function(line, lineIndex)
					run_line(lineIndex+1, stopIndex)
	
func _on_RunButton_pressed():
	variables.clear()
	codeEnd = console.get_line_count()
	run_line(0, codeEnd)
	#$HUD.hide()
	#simulation.start_simulation()

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
	
func string_has(string, s):
	if string.find(s) != null and string.find(s) >= 0:
		return true
	else:
		return false
		
		

 extends Node

onready var console = $HUD/Console
onready var variablesList = $HUD/VariablesContainer/Variables
onready var output = $HUD/OutputContainer/Output
onready var simulation = $Simulation

var codeEnd

var running
var sucess

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

var hudActive = true
var cWhite = Color("#F2F2F2")
var cGreen = Color("#10B33A")
var cRed = Color("#B3101A") 
var cBeje = Color("#FAED7D")

var objectsFunctions = []

var objects = []
var objGetVariables = []
var objSetVariables = []
var objFunctions = []
var simGetVariables
var simSetVariables
var functions = {}

var builtFunctions = {
	"print" : funcref(self, "print_function"),
	"vector": funcref(self, "create_vector_function")
}

func print_variables_list():
	variablesList.push_color(cGreen) 
	variablesList.add_text("Open Variables:\n")
	variablesList.pop()
	if !simSetVariables.empty():
		variablesList.push_color(cBeje) 
		variablesList.add_text("-Simulation\n")
		variablesList.pop()
		variablesList.push_color(cWhite) 
		for i in simSetVariables.keys():
			variablesList.add_text("  ." + i + "\n")
		variablesList.pop()
	if objects.size() > 0:
		for i in range(objects.size()):
			if !objSetVariables[i].empty():
				variablesList.push_color(cBeje) 
				variablesList.add_text("\n-" + objects[i].name + "\n")
				variablesList.pop()
				variablesList.push_color(cWhite) 
				for j in objSetVariables[i].keys():
					variablesList.add_text("  ." + j + "\n")
				variablesList.pop()
	variablesList.push_color(cGreen) 
	variablesList.add_text("\n\nClosed Variables:\n\n")
	variablesList.pop()
	if !simGetVariables.empty():
		variablesList.push_color(cBeje) 
		variablesList.add_text("-Simulation\n")
		variablesList.pop()
		variablesList.push_color(cWhite) 
		for i in simGetVariables.keys():
			variablesList.add_text("  ." + i + "\n")
		variablesList.pop()
	if objects.size() > 0:
		for i in range(objects.size()):
			if !objGetVariables[i].empty():
				variablesList.push_color(cBeje) 
				variablesList.add_text("\n-" + objects[i].name + "\n")
				variablesList.pop()
				variablesList.push_color(cWhite) 
				for j in objGetVariables[i].keys():
					variablesList.add_text("  ." + j + "\n")
				variablesList.pop()

func _on_simulation_end(status):
	if status:
		$ResultLabel.text = "Sucess!"
	else:
		$ResultLabel.text = "Failed :c"
	$ResultLabel.show()

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

func print_function(arguments, lineIndex):
	arguments = arguments[0].replace(" ", "")
	var printContent;
	output.newline()
	if string_has(arguments, "."):
		var objName = arguments.split(".")[0]
		var objVar = arguments.split(".")[1]
		
		if variables.has(objName): #and typeof(variables[objName] == TYPE_VECTOR2):
			match objVar:
				"x":
					output.add_text(str(variables[objName].x))
				"y":
					output.add_text(str(variables[objName].y))
				_:
					crash("invalid vector variables", lineIndex)
	
	if variables.has(arguments):
		output.add_text(str(variables[arguments]))
	elif constVariables.has(arguments):
		output.add_text(str(constVariables[arguments]))

func create_vector_function(arguments,lineIndex):
	var lExpression = arguments[0]
	var rExpression = arguments[1]
	var lResult = calculate_expression(lExpression, lineIndex)
	var rResult = calculate_expression(rExpression, lineIndex)
	return Vector2(lResult, rResult)

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
				
				if variables.has(objName) and typeof(variables[objName]) == TYPE_VECTOR2:
					match objVar:
						"x":
							calc[0] = variables[objName].x
						"y":
							calc[0] = variables[objName].y
						_:
							crash("invalid vector variable", lineIndex)
				
				elif objName == "Simulation":
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
	
func calculate_tree(node, lineIndex):
	if node != null and node[0] != null:
		var res1
		var res2
		if node[1] != null:
			res1 = calculate_tree(node[1], lineIndex)
		if node[2] != null:
			res2 = calculate_tree(node[2], lineIndex)
		match node[0]:
			"%":
				return res1 % res2
			"*":
				if typeof(res1) == TYPE_VECTOR2:
					if typeof(res2) == TYPE_VECTOR2 or typeof(res2) == TYPE_REAL or typeof(res2) == TYPE_INT:
						return res1*res2
					else:
						crash("invalid calculation with vector", lineIndex)
				else:
					return res1 * res2
			"/":
				if typeof(res1) == TYPE_VECTOR2:
					if typeof(res2) == TYPE_VECTOR2 or typeof(res2) == TYPE_REAL or typeof(res2) == TYPE_INT:
						return res1/res2
					else:
						crash("invalid calculation with vector", lineIndex)
				elif typeof(res1) == TYPE_INT and typeof(res2) == TYPE_INT:
					if res1 % res2 != 0:
						return float(res1) / float(res2)
					else:
						return res1 / res2
				else:
					return res1 / res2
			"+":
				if typeof(res1) == TYPE_VECTOR2:
					if typeof(res2) == TYPE_VECTOR2:
						return res1+res2
					else:
						crash("invalid calculation with vector", lineIndex)
				else:
					return res1 + res2
			"-":
				if typeof(res1) == TYPE_VECTOR2:
					if typeof(res2) == TYPE_VECTOR2:
						return res1-res2
					else:
						crash("invalid calculation with vector", lineIndex)
				else:
					return res1 - res2
			_:
				return node[0]
			
func calculate_expression(expression, lineIndex):
	expression = expression.replace(" ", "")
	if string_has(expression, "("):
		var funcName = expression.split("(")[0]
		for f in builtFunctions.keys():
			if funcName == f:
				return read_function(expression, lineIndex)
				
	var calcTree = create_calc_tree(expression, lineIndex)
	return calculate_tree(calcTree, lineIndex)

func calculate_condition(expression, lineIndex):
	if string_has(expression, "("):
		var funcName = expression.split("(")[0]
		for f in builtFunctions.keys():
			if funcName == f:
				return read_function(expression, lineIndex)
				
	var calcTree = create_cond_tree(expression, lineIndex)
	return calculate_cond_tree(calcTree, lineIndex)

func create_cond_tree(expression, lineIndex):
	if expression == "" or expression == null:
		return null
	var calc = [null, null, null]
	var topPos = null
	var top = null
	var c
	var par = 0
	var parTopPos = null
	var parTop = null
	for i in range(expression.length()):
		c = expression[i]
		if c == "(":
			par += 1
		elif c == ")":
			par -= 1
		if c == "!" and expression.length() > i+1 and expression[i+1] != "=":
			if par == 0:
				topPos = i
				top = "!"
			else:
				parTopPos = i
				parTop = "!"
		elif c == "a" and expression.length() > i+2 and expression[i+1] == "n" and expression[i+2] == "d" and expression[i+3] == " ":
			if par == 0:
				topPos = i
				top = "and"
				i += 2
			else:
				parTopPos = i
				parTop = "and"
				i += 2
		elif c == "o" and expression.length() > i+1 and expression[i+1] == "r" and expression[i+2] == " ":
			if par == 0:
				topPos = i
				top = "or"
				i += 1
			else:
				parTopPos = i
				top = "or"
				i += 1
				
			
	if topPos != null:
		calc[0] = top
		match top:
			"!":
				calc[1] = create_cond_tree(expression.substr(topPos+1, expression.length()-(topPos+1)), lineIndex)
			"and":
				calc[1] = create_cond_tree(expression.substr(0, topPos), lineIndex) 
				calc[2] = create_cond_tree(expression.substr(topPos+3, expression.length() - (topPos+3)),lineIndex)
			"or":
				calc[1] = create_cond_tree(expression.substr(0, topPos), lineIndex) 
				calc[2] = create_cond_tree(expression.substr(topPos+2, expression.length() - (topPos+2)),lineIndex)
		return calc
	elif parTopPos != null:
		calc[0] = parTop
		match parTop:
			"!":
				calc[1] = create_cond_tree(expression.substr(parTopPos+1, expression.length()-(parTopPos+1)), lineIndex)
			"and":
				calc[1] = create_cond_tree(expression.substr(0, parTopPos), lineIndex) 
				calc[2] = create_cond_tree(expression.substr(parTopPos+3, expression.length() - (parTopPos+3)),lineIndex)
			"or":
				calc[1] = create_cond_tree(expression.substr(0, parTopPos), lineIndex) 
				calc[2] = create_cond_tree(expression.substr(parTopPos+2, expression.length() - (parTopPos+2)),lineIndex)
		return calc
	else:
		expression = expression.replace("(", "").replace(")", "").replace(" ", "")
		if string_has(expression, "=="):
			if calculate_expression(expression.split("==")[0], lineIndex) == calculate_expression(expression.split("==")[1], lineIndex):
				calc[0] = true
			else:
				calc[0] = false
		elif string_has(expression, "!="):
			if calculate_expression(expression.split("!=")[0], lineIndex) != calculate_expression(expression.split("!=")[1], lineIndex):
				calc[0] = true
			else:
				calc[0] = false
		elif string_has(expression, ">="):
			if calculate_expression(expression.split(">=")[0], lineIndex) >= calculate_expression(expression.split(">=")[1], lineIndex):
				calc[0] = true
			else:
				calc[0] = false
		elif string_has(expression, ">"):
			if calculate_expression(expression.split(">")[0], lineIndex) > calculate_expression(expression.split(">")[1], lineIndex):
				calc[0] = true
			else:
				calc[0] = false
		elif string_has(expression, "<="):
			if calculate_expression(expression.split("<=")[0], lineIndex) <= calculate_expression(expression.split("<=")[1], lineIndex):
				calc[0] = true
			else:
				calc[0] = false
		elif string_has(expression, "<"):
			if calculate_expression(expression.split("<")[0], lineIndex) < calculate_expression(expression.split("<")[1], lineIndex):
				calc[0] = true
			else:
				calc[0] = false
		else:
			if string_has(expression, "."):
				var objName = expression.split(".")[0]
				var objVar = expression.split(".")[1]
				if objName == "Simulation":
					if !simGetVariables.empty() and simGetVariables.has(objVar):
						calc[0] = simGetVariables[objVar].call_func()
						if calc[0] != true and calc[0] != false:
							crash("non boolean value on comparation", lineIndex)
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
						if calc[0] != true and calc[0] != false:
							crash("non boolean value on comparation", lineIndex)
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

func calculate_cond_tree(node, lineIndex):
	if node == null or node[0] == null:
		return null
	
	var res1 = node[1]
	var res2 = node[2]
	
	match node[0]:
		true:
			return true
		false:
			return false
		"!":
			return ! calculate_cond_tree(res1, lineIndex)
		"and":
			return calculate_cond_tree(res1, lineIndex) and calculate_cond_tree(res2, lineIndex)
		"or":
			return calculate_cond_tree(res1, lineIndex) or calculate_cond_tree(res2, lineIndex)
	
	return null
	
func process_assignment(line, lineIndex):
	line = line.replace("	", "")
	var varName = line.split(" = ")[0]
	var varVariable = null
	var isObject = false
	var isFunction = false
	var expression = line.split(" = ")[1]
	
	if string_has(varName, "."):
		varVariable = varName.split(".")[1]
		varName = varName.split(".")[0]
		if variables.has(varName) and typeof(variables[varName]) == TYPE_VECTOR2:
			match varVariable:
				"x":
					variables[varName].x = calculate_expression(expression, lineIndex)
				"y":
					variables[varName].y = calculate_expression(expression, lineIndex)
				_:
					crash("invalid vector variable", lineIndex)
		elif varName == "Simulation":
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
	output.add_text("Error: " + error + ". For line: " + str(line + 1))
	print("\nError: " + error + ". For line: " + str(line + 1))

func create_variable(line, lineIndex):
	var varName = line.split(" ", false, 2)[1]
	variable_creation(varName, lineIndex)
	if line.split(" ")[2] == "=":
		var assignmentLine = line.replace("var ", "")
		process_assignment(assignmentLine, lineIndex)
		
func variable_creation(varName, lineIndex):
	for i in variables:
		if i == varName:
			crash("variable already exists", lineIndex)
	variables[varName] = null
	
func get_end_bracket(startIndex, tabs):
	for i in range(startIndex, codeEnd):
		if console.get_line(i).find("	") != tabs:
			pass
		elif string_has(console.get_line(i), "}"):
			return i
	crash("Expecting } ", startIndex)

func get_chain_end_line(startIndex):
	startIndex += 1
	for i in range(startIndex, codeEnd):
		if console.get_line(i)[0] == "":
			pass
		elif string_has(console.get_line(i), "elif"):
			var newIndex = get_end_bracket(i, console.get_line(i).find("	"))
			return get_chain_end_line(newIndex)
		elif string_has(console.get_line(i), "else"):
			return get_end_bracket(i, console.get_line(i).find("	"))
		else:
			return i

func look_for_else(startIndex):
	startIndex += 1
	for i in range(startIndex, codeEnd):
		if console.get_line(i) == "":
			pass
		elif string_has(console.get_line(i), "elif"):
			return [i, true]
		elif string_has(console.get_line(i),"else"):
			return [i, false]
		else:
			return [-1, false]

func handle_condition(lineIndex, stopIndex):
	var line = console.get_line(lineIndex)
	var condition
	if string_has(line, "if"): 
		condition = line.split("if")[1]
	else:
		condition = line.split("elif")[1]
	condition = condition.substr(condition.find("(") + 1, condition.find_last(")") - condition.find("(") - 1)
	condition = calculate_condition(condition, lineIndex)
	
	var stopConditionIndex = get_end_bracket(lineIndex, line.find("	"))
	
	if condition:
		run_line(lineIndex + 1, stopConditionIndex)
		var endChainIndex = get_chain_end_line(stopConditionIndex)
		run_line(endChainIndex, stopIndex)
	else:
		var nextConditionIndex = [null, null]
		nextConditionIndex = look_for_else(stopConditionIndex)
		if nextConditionIndex[0] == null or nextConditionIndex[0] == -1:
			run_line(stopConditionIndex, stopIndex)
		elif nextConditionIndex[1]:
			handle_condition(nextConditionIndex[0], stopIndex)
		elif !nextConditionIndex[1] and nextConditionIndex[0] != null:
			run_line(nextConditionIndex[0]+1, stopIndex)
		else:
			run_line(stopConditionIndex, stopIndex)

func read_function(expression, lineIndex):
	expression = expression.replace("	", "")
	var f = expression.split("(", true, 1)[0]
	var arguments = expression.split("(", true, 1)[1].rsplit(")", true, 1)[0].split(",")
	if builtFunctions.has(f):
		return builtFunctions[f].call_func(arguments, lineIndex)
	else:
		crash("invalid function", lineIndex)
	
func handle_for_loop(lineIndex, stopIndex):
	var line = console.get_line(lineIndex)
	var varName = line.split(" ")[1]
	variable_creation(varName, lineIndex)
	var duration = line.split(" ", true, 2)[2]
	duration = duration.substr(duration.find("(") + 1, duration.find_last(")") - duration.find("(") - 1)
	duration = int(calculate_expression(duration, lineIndex))
	
	var loopEnd = get_end_bracket(lineIndex, line.find("	"))
	
	for i in range(duration):
		variables[varName] = i
		run_line(lineIndex+1, loopEnd)
		i = int(variables[varName])
		
	variables.erase(varName)
	run_line(loopEnd, stopIndex)
	
func handle_while_loop(lineIndex, stopIndex):
	var line = console.get_line(lineIndex)
	var condition = line.split("while", true, 1)[1]
	condition = condition.substr(condition.find("(") + 1, condition.find_last(")") - condition.find("(") - 1)
	var loopEnd = get_end_bracket(lineIndex, line.find("	"))
	var infLoopBreaker = 0
	while(calculate_condition(condition, lineIndex) and infLoopBreaker < 10000):
		run_line(lineIndex+1, loopEnd)
		infLoopBreaker += 1
		if infLoopBreaker > 10000:
			crash("infinite loop", lineIndex)
	run_line(loopEnd, stopIndex)
	
func run_line(lineIndex, stopIndex):
	var line = console.get_line(lineIndex)
	var lineNoTabs = line
	if line != "" and line[0] == "	":
		lineNoTabs = line.replace("	", "")
	
	var sections = lineNoTabs.split(" ", false)
	if lineIndex == null or lineIndex > stopIndex:
		pass
	elif lineNoTabs == "}" or lineNoTabs == "":
		run_line(lineIndex+1, stopIndex)
	else:
		if sections.size() > 1 and sections[0] == "var":
			create_variable(line, lineIndex)
			run_line(lineIndex+1, stopIndex)
			
		elif sections.size() > 1 and sections[1] == "=":
			process_assignment(line, lineIndex)
			run_line(lineIndex+1, stopIndex)
			
		elif string_has(line, "if"):
			handle_condition(lineIndex, stopIndex)
		
		elif string_has(line, "while"):
			handle_while_loop(lineIndex, stopIndex)
		elif string_has(line, "for"):
			handle_for_loop(lineIndex, stopIndex)
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
	output.newline()
	run_line(0, codeEnd)
	console.readonly = true
	$HUD.hide()
	hudActive = false
	simulation.start_simulation()

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
		
func _on_SwapButton_pressed():
	if hudActive:
		$HUD.hide()
		hudActive = false
	else:
		$HUD.show()
		hudActive = true
		


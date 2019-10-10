extends TextEdit

var varColor = Color( 1, 0.65, 0, 1 )
var numberColor = Color("#faf09b")
var selectionColor = Color(.75,.75,.75,1)
var primitiveFuncColor = Color( 0.8, 0.36, 0.36, 1 )
var funcColor = Color( 0.12, 0.56, 1, 1 )

var primitiveFuncKeywords = ["if", "elif", "else", "while", "for", "and", "!", "or"]
var funcKeywords = ["print", "vector", "var"]

func _ready():
	theme.set_color("number_color", "TextEdit",  numberColor) 
	theme.set_color("selection_color", "TextEdit", selectionColor)
	theme.set_color("line_number_color", "TextEdit", Color(1,1,1,1))
	theme.set_color("member_variable_color", "TextEdit", selectionColor)
	theme.set_color("breakpoint_color", "TextEdit", Color("002f213b"))
	
	for keyword in primitiveFuncKeywords:
		add_keyword_color(keyword, primitiveFuncColor)
		
	for keyword in funcKeywords:
		add_keyword_color(keyword, funcColor)
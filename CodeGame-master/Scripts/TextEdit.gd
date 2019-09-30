extends TextEdit

var varColor = Color( 1, 0.65, 0, 1 )
var numberColor = Color("#faf09b")
var primitiveFuncColor = Color( 0.8, 0.36, 0.36, 1 )
var funcColor = Color( 0.12, 0.56, 1, 1 )

var primitiveFuncKeywords = ["if", "elif", "else", "loop"]
var funcKeywords = ["print"]

func _ready():
	theme.set_color("number_color", "TextEdit",  numberColor) 
	
	for keyword in primitiveFuncKeywords:
		add_keyword_color(keyword, primitiveFuncColor)
		
	for keyword in funcKeywords:
		add_keyword_color(keyword, funcColor)
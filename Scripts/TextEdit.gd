extends TextEdit

var varColor = Color( 1, 0.65, 0, 1 )
var numberColor = Color("#faf09b")
var funcColor = Color( 0.8, 0.36, 0.36, 1 )

var funcKeywords = ["if", "elif", "else", "print"]

func _ready():
	theme.set_color("number_color", "TextEdit",  numberColor) 
	#add_color_region('!', '~', Color( 0, 0, 0, 1 ), true)

	
	for keyword in funcKeywords:
		add_keyword_color(keyword, funcColor)
package lexer

type TokenType string

const (
	IDENTIFIER TokenType = "IDENTIFIER"
	TRUE       TokenType = "TRUE"
	FALSE      TokenType = "FALSE"
	NONE       TokenType = "NONE"
	NEWLINE    TokenType = "NEWLINE"

	// punctuation
	COMMA            TokenType = "COMMA"
	SEMI_COLON       TokenType = "SEMI_COLON"
	COLON            TokenType = "COLON"
	PERIOD           TokenType = "PERIOD"
	EXCLAMATION_MARK TokenType = "EXCLAMATION_MARK"
	QUESTION_MARK    TokenType = "QUESTION_MARK"

	// parens
	LEFT_PAREN    TokenType = "LEFT_PAREN"
	RIGHT_PAREN   TokenType = "RIGHT_PAREN"
	LEFT_BRACE    TokenType = "LEFT_BRACE"
	RIGHT_BRACE   TokenType = "RIGHT_BRACE"
	LEFT_BRACKET  TokenType = "LEFT_BRACKET"
	RIGHT_BRACKET TokenType = "RIGHT_BRACKET"
	LEFT_CARROT   TokenType = "LEFT_CARROT"
	RIGHT_CARROT  TokenType = "RIGHT_CARROT"

	// inequalities
	LESS_THAN_EQ TokenType = "LESS_THAN_EQ"
	GRTR_THAN_EQ TokenType = "GRTR_THAN_EQ"
	EQUAL_SIGN   TokenType = "EQUAL_SIGN"
	DOUBLE_EQUAL TokenType = "DOUBLE_EQUAL"

	// MATH
	PLUS       TokenType = "PLUS"
	MINUS      TokenType = "MINUS"
	TIMES      TokenType = "TIMES"
	POWER      TokenType = "POWER"
	PERCENT    TokenType = "PERCENT"
	FRWD_SLASH TokenType = "FRWD_SLASH"
	BACK_SLASH TokenType = "BACK_SLASH"
)

var BaseTokens = map[string]TokenType{
	"true":  TRUE,
	"false": FALSE,
	"none":  NONE,
	"\n":    NEWLINE,

	// punctuation
	",": COMMA,
	";": SEMI_COLON,
	":": COLON,
	".": PERIOD,
	"!": EXCLAMATION_MARK,
	"?": QUESTION_MARK,

	// parens
	"(": LEFT_PAREN,
	")": RIGHT_PAREN,
	"{": LEFT_BRACE,
	"}": RIGHT_BRACE,
	"[": LEFT_BRACKET,
	"]": RIGHT_BRACKET,
	"<": LEFT_CARROT,
	">": RIGHT_CARROT,

	// inequalities
	"<=": LESS_THAN_EQ,
	">=": GRTR_THAN_EQ,
	"=":  EQUAL_SIGN,
	"==": DOUBLE_EQUAL,

	// MATH
	"+":  PLUS,
	"-":  MINUS,
	"*":  TIMES,
	"^":  POWER,
	"%":  PERCENT,
	"/":  FRWD_SLASH,
	"\\": BACK_SLASH,
}

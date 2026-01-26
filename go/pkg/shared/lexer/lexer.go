package lexer

import (
	"kernellesoft/hyper/pkg/shared/slice"
	"maps"
	"os"
	"unicode"
)

type BaseLexer struct {
	Content  string
	FilePath string
}

const END_OF_FILE = "END_OF_FILE"

type Token struct {
	Type  TokenType
	Value string
}

func New(filePath string) *BaseLexer {
	content, err := os.ReadFile(filePath)
	if err != nil {
		panic(err)
	}

	return &BaseLexer{string(content), filePath}
}

func (lexer *BaseLexer) Read() []Token {
	remaining := lexer.Content
	tokens := []Token{}

	for {
		if len(remaining) == 0 {
			break
		}

		tok, err := lexer.lex(remaining)
		if err != nil {
			panic(err)
		}

		tokens = append(tokens, tok)
		remaining = remaining[len(tok.Value):]
	}

	return tokens
}

func (lexer *BaseLexer) lex(src string) (Token, error) {
	char := src[:1]
	if lexer.isWhitespace(char) {
		lexer.stripWhitespace(src)
	} else if lexer.isBaseToken(char) {
		return lexer.extractBaseToken(src), nil
	}

	return lexer.extractIdentifier(src), nil
}

var WhiteSpace = []string{" ", "\t"}

func (lexer *BaseLexer) isWhitespace(src string) bool {
	c := src[0]
	return slice.Contains(WhiteSpace, string(c))
}

func (lexer *BaseLexer) stripWhitespace(src string) string {
	c := ""
	length := 0
	for {
		c = string(src[length])
		if !slice.Contains(WhiteSpace, c) {
			break
		}

		length += 1
	}
	return string(src[length:])
}

func (lexer *BaseLexer) isBaseToken(src string) bool {
	for key := range maps.Keys(BaseTokens) {
		if len(key) > len(src) {
			continue
		}

		match := true
		for i := 1; i <= len(key); i++ {
			if key[:i] != src[:i] {
				match = false
				break
			}
		}

		if match {
			return true
		}
	}
	return false
}

func (lexer *BaseLexer) extractBaseToken(src string) Token {
	for key := range BaseTokens {
		if len(key) > len(src) {
			continue
		}

		match := true
		for i := 1; i <= len(key); i++ {
			if key[:i] != src[:i] {
				match = false
				break
			}
		}

		if match {
			return Token{BaseTokens[key], key}
		}
	}
	return Token{"", ""}
}

func (lexer *BaseLexer) extractIdentifier(src string) Token {
	length := 1
	c := src[length]
	for {
		if !unicode.IsNumber(rune(c)) && !unicode.IsLetter(rune(c)) && c != '_' {
			break
		}

		length += 1
	}

	return Token{IDENTIFIER, src[:length]}
}

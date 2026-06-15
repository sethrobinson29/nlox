import std/strutils
import std/tables
import ./token
import ./error

type 
    Scanner* = object
        source*: string
        tokens: seq[Token] = @[]
        start: int = 0
        current: int = 0
        line: int = 1

const keywords = {
    "and": tkAnd,
    "class": tkClass,
    "else": tkElse,
    "false": tkFalse,
    "for": tkFor,
    "fun": tkFun,
    "if": tkIf,
    "nil": tkNil,
    "or": tkOr,
    "print": tkPrint,
    "return": tkReturn,
    "super": tkSuper,
    "this": tkThis,
    "true": tkTrue,
    "var": tkVar,
    "while": tkWhile,
    "break": tkBreak
}.toTable()

proc isAtEnd(s: Scanner): bool = 
    result = s.current >= s.source.len

proc addToken(s: var Scanner, tokenType: TokenType, literal: Literal = initLiteral()) = 
    let text = s.source[s.start..<s.current]
    s.tokens.add(Token(tkType: tokenType, lexeme: text, literal: literal, line: s.line))

proc advance(s: var Scanner): char =
    result = s.source[s.current]
    inc s.current

proc peek(s: Scanner): char = 
    if (s.isAtEnd()): return '\0'
    result = s.source[s.current]

proc peekNext(s: Scanner): char = 
    if (s.current + 1 >= s.source.len): return '\0'
    result = s.source[s.current + 1]

proc match(s: var Scanner, expected: char): bool = 
    if (s.isAtEnd()) or s.source[s.current] != expected: return false
    inc s.current
    result = true

proc handleString(s: var Scanner) = 
    while (s.peek() != '"' and not s.isAtEnd()):
        if (s.peek() == '\n'): inc s.line
        discard s.advance()
    
    if (s.isAtEnd()):
        loxError(s.line, "Unterminated string")
        return
    
    discard s.advance()
    let value = s.source[s.start+1..<s.current-1]
    s.addToken(tkString, initLiteral(value))

proc handleNumber(s: var Scanner) = 
    while (isDigit(s.peek())): discard s.advance()

    if (s.peek() == '.' and isDigit(s.peekNext())):
        discard s.advance()
        while (isDigit(s.peek())): discard s.advance()
    
    try:
        let value = parseFloat(s.source[s.start..<s.current])
        s.addToken(tkNumber, initLiteral(value))
    except ValueError:
        loxError(s.line, "Invalid number.")

proc handleIdentifier(s: var Scanner) = 
    while (isAlphaNumeric(s.peek())): discard s.advance()

    let text = s.source[s.start..<s.current]
    let tokenType = keywords.getOrDefault(text, tkIdentifier)
    s.addToken(tokenType)

proc scanToken(s: var Scanner) = 
    let c = s.advance()
    case c
    # characters
    of '(': s.addToken(tkLeftParen)
    of ')': s.addToken(tkRightParen)
    of '{': s.addToken(tkLeftBrace)
    of '}': s.addToken(tkRightBrace)
    of ',': s.addToken(tkComma)
    of '.': s.addToken(tkDot)
    of '-': s.addToken(tkMinus)
    of '+': s.addToken(tkPlus)
    of ';': s.addToken(tkSemicolon)
    of '*': s.addToken(tkStar)
    of '!': s.addToken(if s.match('='): tkBangEqual else: tkBang)
    of '=': s.addToken(if s.match('='): tkEqualEqual else: tkEqual)
    of '<': s.addToken(if s.match('='): tkLessEqual else: tkLess)
    of '>': s.addToken(if s.match('='): tkGreaterEqual else: tkGreater)
    of '/':
        if s.match('/'):
            while s.peek() != '\n' and not s.isAtEnd(): discard s.advance()
        elif s.match('*'):
            while not s.isAtEnd():
                if s.peek() == '*' and s.peekNext() == '/':
                    discard s.advance()
                    discard s.advance()
                    break
                if s.peek() == '\n': inc s.line
                discard s.advance()
        else:
            s.addToken(tkSlash)
    of '\n': inc s.line
    of ' ', '\r', '\t': discard
    # string literals
    of '"': s.handleString()
    else:
        if (isDigit(c)):
            s.handleNumber()
        elif isAlphaAscii(c):
            s.handleIdentifier()
        else:
            loxError(s.line, "Unexpected character.")

proc scanTokens*(s: var Scanner): seq[Token] = 
    while (not s.isAtEnd()):
        s.start = s.current
        s.scanToken()

    s.tokens.add(Token(tkType: tkEof, lexeme: "", literal: initLiteral(), line: s.line))
    result = s.tokens
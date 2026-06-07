import ./token
import ./error

type 
    Scanner* = object
        source*: string
        tokens: seq[Token] = @[]
        start: int = 0
        current: int = 0
        line: int = 1

proc isAtEnd(s: Scanner): bool = 
    result = s.current >= s.source.len

proc addToken(s: var Scanner, tokenType: TokenType, literal: Literal = Literal(kind: lkNil)) = 
    let text = s.source[s.start..<s.current]
    s.tokens.add(Token(tkType: tokenType, lexeme: text, literal: literal, line: s.line))

proc advance(s: var Scanner): char =
    result = s.source[s.current]
    inc s.current

proc peek(s: Scanner): char = 
    if (s.isAtEnd()): return '\0'
    result = s.source[s.current]

proc match(s: var Scanner, expected: char): bool = 
    if (s.isAtEnd()) or s.source[s.current] != expected: return false
    inc s.current
    result = true


proc scanToken(s: var Scanner) = 
    let c = s.advance()
    case c
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
        if (s.match('/')):
            while (s.peek() != '\n' and not s.isAtEnd()): discard s.advance()
        else:
            s.addToken(tkSlash)
    of '\n': inc s.line
    of ' ', '\r', '\t': discard
    else:
        loxError(s.line, "Unexpected character.")

proc scanTokens*(s: var Scanner): seq[Token] = 
    while (not s.isAtEnd()):
        s.start = s.current
        s.scanToken()

    s.tokens.add(Token(tkType: tkEof, lexeme: "", literal: Literal(kind: lkNil), line: s.line))
    result = s.tokens
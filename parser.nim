import ./token
import ./exprsn
import ./error

type 
    Parser* = object
        tokens*: seq[Token]
        current: int = 0

proc expression(p: var Parser): Expr
proc parseError(p: var Parser, message: string): ref ParseError


proc parse*(p: var Parser): Expr = 
    try:
        result = p.expression()
    except ParseError:
        result = nil

proc peek(p: var Parser): Token = 
    result = p.tokens[p.current]

proc previous(p: var Parser): Token = 
    result = p.tokens[p.current - 1]

proc isAtEnd(p: var Parser): bool = 
    result = (p.peek().tkType) == tkEof

proc advance(p: var Parser): Token = 
    if (not p.isAtEnd()): inc p.current
    result = p.previous()

proc check(p: var Parser, t: TokenType): bool = 
    if (p.isAtEnd()): return false
    result = p.peek().tkType == t

proc consume(p: var Parser, t: TokenType, message: string): Token = 
    if (p.check(t)): 
        return p.advance()
    loxError(p.peek(), message)
    raise p.parseError(message)

proc match(p: var Parser, types: varargs[TokenType]): bool = 
    for t in types:
        if (p.check(t)):
            discard p.advance()
            return true
    
    result = false

proc primary(p: var Parser): Expr = 
    if (p.match(tkFalse)): return newLiteral(initLiteral(false))
    if (p.match(tkTrue)): return newLiteral(initLiteral(true))
    if (p.match(tkNil)): return newLiteral(initLiteral())

    if (p.match(tkNumber, tkString)): return newLiteral(p.previous().literal)

    if (p.match(tkLeftParen)):
        let ex = p.expression()
        discard p.consume(tkRightParen, "Except ')' after expression.")
        return newGrouping(ex)

    raise p.parseError("Expect expression")

proc unary(p: var Parser): Expr = 
    if (p.match(tkBang, tkMinus)):
        let operator = p.previous()
        let right = p.unary()
        return newUnary(operator, right)

    result = p.primary()

proc factor(p: var Parser): Expr = 
    var ex = p.unary()

    while (p.match(tkSlash, tkStar)):
        let operator = p.previous()
        let right = p.unary()
        ex = newBinary(ex, operator, right)
    
    result = ex

proc comparison(p: var Parser): Expr =
    var ex = p.factor()

    while (p.match(tkMinus, tkPlus)):
        let operator = p.previous()
        let right = p.factor()
        ex = newBinary(ex, operator, right)

    result = ex

proc equality(p: var Parser): Expr =
    var ex = p.comparison()

    while (p.match(tkBangEqual, tkEqualEqual)):
        let operator = p.previous()
        let right = p.comparison()
        ex = newBinary(ex, operator, right)
    
    result = ex

proc expression(p: var Parser): Expr = 
    result = p.equality()

proc parseError(p: var Parser, message: string): ref ParseError =
    loxError(p.peek(), message)
    result = newException(ParseError, message)

proc synchronize(p: var Parser) = 
    discard p.advance()
    
    while (not p.isAtEnd()):
        if (p.previous().tkType == tkSemicolon): return
        
        case p.peek().tkType:
        of tkClass, tkFun, tkVar, tkFor, tkIf, tkWhile, tkPrint, tkReturn:
            return
        else: 
            discard
    
    discard p.advance()
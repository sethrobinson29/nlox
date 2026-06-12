type 
    TokenType* = enum
        # single characters
        tkLeftParen, tkRightParen, tkLeftBrace, tkRightBrace,
        tkComma, tkDot, tkMinus, tkPlus, tkSemicolon, tkSlash, tkStar

        # 1 or 2 characters
        tkBang, tkBangEqual, tkEqual, tkEqualEqual, tkGreater,
        tkGreaterEqual, tkLess, tkLessEqual

        # literals
        tkIdentifier, tkString, tkNumber

        # keywords
        tkAnd, tkClass, tkElse, tkFalse, tkFun, tkFor,
        tkIf, tkNil, tkOr, tkPrint, tkReturn, tkSuper,
        tkThis, tkTrue, tkVar, tkWhile

        tkEof
    
    LiteralKind* = enum
        lkNil, lkBool, lkFloat, lkString

    Literal* = object
        case kind*: LiteralKind
        of lkNil: discard
        of lkBool: boolVal*: bool
        of lkFloat: floatVal*: float
        of lkString: strVal*: string

    Token* = object
        tkType*: TokenType
        lexeme*: string
        literal*: Literal
        line*: int

# Literal constructors
proc initLiteral*(s: string): Literal = Literal(kind: lkString, strVal: s)
proc initLiteral*(b: bool): Literal = Literal(kind: lkBool, boolVal: b)
proc initLiteral*(f: float): Literal = Literal(kind: lkFloat, floatVal: f)
proc initLiteral*(): Literal = Literal(kind: lkNil)

# Literals to string
proc `$`*(lit: Literal): string = 
    case lit.kind
    of lkNil: "nil"
    of lkBool: $lit.boolVal
    of lkFloat: 
        let f = lit.floatVal
        if f == f.int.float:
            $f.int
        else: 
            $f
    of lkString: lit.strVal

proc tkToString*(token: Token): string = 
    result = $token.tkType & " " & token.lexeme & " " & $token.literal
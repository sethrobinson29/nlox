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

proc `$`*(lit: Literal): string = 
    case lit.kind
    of lkNil: "nil"
    of lkBool: $lit.boolVal
    of lkFloat: $lit.floatVal
    of lkString: lit.strVal

proc tkToString*(token: Token): string = 
    result = $token.tkType & " " & token.lexeme & " " & $token.literal
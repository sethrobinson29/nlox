# literal functionality
import ./types

# Literal constructors
proc initLiteral*(s: string): Literal = Literal(kind: lkString, strVal: s)
proc initLiteral*(b: bool): Literal = Literal(kind: lkBool, boolVal: b)
proc initLiteral*(f: float): Literal = Literal(kind: lkFloat, floatVal: f)
proc initLiteral*(fn: LoxFunction): Literal = Literal(kind: lkFunction, function: fn)
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
    of lkFunction:
        case lit.function.kind:
            of lfNative: "<native fn>"
            of lfLox: "<f" & lit.function.declaration.funcName.lexeme & ">"

    else:
        # todo
        ""

proc tkToString*(token: Token): string = 
    result = $token.tkType & " " & token.lexeme & " " & $token.literal
# literal functionality
import ./types

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
    else:
        # todo
        ""

proc tkToString*(token: Token): string = 
    result = $token.tkType & " " & token.lexeme & " " & $token.literal


proc arity*(lit: Literal): int =
    case lit.kind:
    of lkFunction: lit.function.declaration.params.len
    of lkClass: 0  # todo: check for init method later
    else: 0
import ./token

type 
    ExprKind* = enum
        ekBinary, ekUnary, ekLiteral, ekGrouping, ekVar, ekAssign

    Expr* = ref object
        case kind*: ExprKind
        of ekBinary:
            left*: Expr
            operator*: Token
            right*: Expr
        of ekUnary:
            unaryOp*: Token
            unaryRight*: Expr
        of ekLiteral:
            value*: Literal
        of ekGrouping:
            expression*: Expr
        of ekVar:
            name*: Token
        of ekAssign:
            token*: Token
            assignExpr*: Expr

# Expr constructors
proc newBinary*(leftExpr: Expr, op: Token, rightExpr: Expr): Expr = Expr(kind: ekBinary, left: leftExpr, operator: op, right: rightExpr)
proc newUnary*(operator: Token, right: Expr): Expr = Expr(kind: ekUnary, unaryOp: operator, unaryRight: right)
proc newLiteral*(val: Literal): Expr = Expr(kind: ekLiteral, value: val)
proc newGrouping*(ex: Expr): Expr = Expr(kind: ekGrouping, expression: ex)
proc newVariable*(name: Token): Expr = Expr(kind: ekVar, name: name)
proc newAssignment*(token: Token, ex: Expr): Expr = Expr(kind: ekAssign, token: token, assignExpr: ex)

proc `$`*(ex: Expr): string =
    if (ex == nil): return "nil"
    case ex.kind
    of ekBinary: "(" & $ex.operator.lexeme & " " & $ex.left & " " & $ex.right & ")"
    of ekUnary: "(" & $ex.unaryOp.lexeme & " " & $ex.unaryRight & ")"
    of ekLiteral: $ex.value
    of ekGrouping: "(group " & $ex.expression & ")"
    of ekVar: ex.name.lexeme
    of ekAssign: "(= " & ex.name.lexeme & " " & $ex.value & ")"
# expression functionality 
import ./types

# Expr constructors
proc newBinary*(leftExpr: Expr, op: Token, rightExpr: Expr): Expr = Expr(kind: ekBinary, left: leftExpr, operator: op, right: rightExpr)
proc newUnary*(operator: Token, right: Expr): Expr = Expr(kind: ekUnary, unaryOp: operator, unaryRight: right)
proc newLiteral*(val: Literal): Expr = Expr(kind: ekLiteral, value: val)
proc newGrouping*(ex: Expr): Expr = Expr(kind: ekGrouping, expression: ex)
proc newVariable*(name: Token): Expr = Expr(kind: ekVar, name: name)
proc newAssignment*(token: Token, ex: Expr): Expr = Expr(kind: ekAssign, token: token, assignExpr: ex)
proc newCall*(callee: Expr, paren: Token, args: seq[Expr]): Expr = Expr(kind: ekCall, callee: callee, paren: paren, args: args)
proc newAnonFunction*(params: seq[Token], body: seq[Stmt]): Expr = Expr(kind: ekFunction, params: params, body: body)
proc newGetProp*(obj: Expr, name: Token): Expr = Expr(kind: ekGetProp, getPropObj: obj, getPropName: name)
proc newSetProp*(obj: Expr, name: Token, val: Expr): Expr = Expr(kind: ekSetProp, setPropObj: obj, setPropName: name, setPropVal: val)
proc newThis*(keyword: Token, depth: int = -1): Expr = Expr(kind: ekThis, thisKeyword: keyword, thisDepth: depth)

proc `$`*(ex: Expr): string =
    if (ex == nil): return "nil"
    case ex.kind
    of ekBinary: "(" & $ex.operator.lexeme & " " & $ex.left & " " & $ex.right & ")"
    of ekUnary: "(" & $ex.unaryOp.lexeme & " " & $ex.unaryRight & ")"
    of ekLiteral: $ex.value
    of ekGrouping: "(group " & $ex.expression & ")"
    of ekVar: ex.name.lexeme
    of ekAssign: "(= " & ex.name.lexeme & " " & $ex.value & ")"
    of ekCall: "func [" & $ex.callee & "] with args ( " & $ex.args & " )" 
    of ekFunction: "anon func with args ( " & $ex.params & " )"
    else: 
        ""
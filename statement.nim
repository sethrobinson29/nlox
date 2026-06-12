import ./expression
import ./token

type 
    StmtKind* = enum 
        skExpression, skPrint, skVar

    Stmt* = ref object
        case kind*: StmtKind
        of skExpression: 
            expression*: Expr
        of skPrint:
            printExpr*: Expr
        of skVar:
            name*: Token
            varExpr*: Expr

proc newExpressionStmt*(ex: Expr): Stmt = 
    Stmt(kind: skExpression, expression: ex)

proc newPrintStmt*(ex: Expr): Stmt = 
    Stmt(kind: skPrint, printExpr: ex)

proc newVarStmt*(name: Token, varExpr: Expr): Stmt = 
    Stmt(kind:skVar, name: name, varExpr: varExpr)    
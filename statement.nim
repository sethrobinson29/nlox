import ./expression
import ./token

type 
    StmtKind* = enum 
        skExpression, skPrint, skVar, skBlock

    Stmt* = ref object
        case kind*: StmtKind
        of skExpression: 
            expression*: Expr
        of skPrint:
            printExpr*: Expr
        of skVar:
            name*: Token
            varExpr*: Expr
        of skBlock:
            statements*: seq[Stmt]

proc newExpressionStmt*(ex: Expr): Stmt = 
    Stmt(kind: skExpression, expression: ex)

proc newPrintStmt*(ex: Expr): Stmt = 
    Stmt(kind: skPrint, printExpr: ex)

proc newVarStmt*(name: Token, varExpr: Expr): Stmt = 
    Stmt(kind: skVar, name: name, varExpr: varExpr)   

proc newBlockStmt*(stmts: seq[Stmt]): Stmt = 
    Stmt(kind: skBlock, statements: stmts)
import ./expression
import ./token

type 
    StmtKind* = enum 
        skExpression, skPrint, skVar, skBlock, skIf, skWhile, skBreak

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
        of skIf:
            condition*: Expr
            thenBranch*: Stmt
            elseBranch*: Stmt
        of skWhile:
            con*: Expr
            body*: Stmt
        of skBreak:
            discard
        

proc newExpressionStmt*(ex: Expr): Stmt = 
    Stmt(kind: skExpression, expression: ex)

proc newPrintStmt*(ex: Expr): Stmt = 
    Stmt(kind: skPrint, printExpr: ex)

proc newVarStmt*(name: Token, varExpr: Expr): Stmt = 
    Stmt(kind: skVar, name: name, varExpr: varExpr)   

proc newBlockStmt*(stmts: seq[Stmt]): Stmt = 
    Stmt(kind: skBlock, statements: stmts)

proc newIfStmt*(condition: Expr, thenBranch: Stmt, elseBranch: Stmt): Stmt = 
    Stmt(kind: skIf, condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)

proc newWhileStmt*(con: Expr, body: Stmt): Stmt = 
    Stmt(kind: skWhile, con: con, body: body)

proc newBreakStmt*(): Stmt = 
    Stmt(kind: skBreak)
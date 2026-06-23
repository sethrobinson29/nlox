# statement functionality
import ./types
        

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

proc newFunctionStmt*(name: Token, params: seq[Token], body: seq[Stmt]): Stmt = 
    Stmt(kind: skFunction, funcName: name, params: params, funcBody: body)

proc newClassStmt*(name: Token, methods: seq[Stmt]): Stmt = 
    Stmt(kind: skClass, className: name, methods: methods)

proc newReturnStmt*(keyword: Token, value: Expr): Stmt = 
    Stmt(kind: skReturn, keyword: keyword, value: value)

proc newBreakStmt*(): Stmt = 
    Stmt(kind: skBreak)
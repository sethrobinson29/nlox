import std/tables
import ./types
import ./error

proc resolveStmt*(r: var Resolver, st: Stmt)
proc resolveFunction*(r: var Resolver, params: seq[Token], body: seq[Stmt])

# stack operations
proc beginScope*(r: var Resolver) = 
    r.scopes.add(initTable[string, bool]())

proc endScope*(r: var Resolver) = 
    discard r.scopes.pop()

# table operations
proc declare*(r: var Resolver, name: Token) = 
    if (r.scopes.len == 0): return
    if (r.scopes[^1].hasKey(name.lexeme)):
        loxError(name, "Already a variable with this name in this scope.")
    r.scopes[^1][name.lexeme] = false

proc define*(r: var Resolver, name: Token) =
    if (r.scopes.len == 0): return
    r.scopes[^1][name.lexeme] = true

# resolve scopes
proc resolveLocal*(r: var Resolver, ex: Expr, name: Token) =
    let lastIndex = r.scopes.len - 1
    for i in countdown(lastIndex, 0):
        if (r.scopes[i].hasKey(name.lexeme)):
            var depth = lastIndex - i
            case ex.kind:
            of ekVar:
                ex.varDepth = depth
            of ekAssign:
                ex.assignDepth = depth
            else:
                discard
            return 

proc resolveExpr*(r: var Resolver, ex: Expr) =
    case ex.kind:
    of ekVar:
        resolveLocal(r, ex, ex.name)
    of ekAssign:
        resolveExpr(r, ex.assignExpr)
        resolveLocal(r, ex, ex.token)
    of ekBinary:
        resolveExpr(r, ex.left)
        resolveExpr(r, ex.right)
    of ekUnary:
        resolveExpr(r, ex.unaryRight)
    of ekGrouping:
        resolveExpr(r, ex.expression)
    of ekLiteral:
        discard
    of ekCall:
        resolveExpr(r, ex.callee)
        for arg in ex.args:
            resolveExpr(r, arg)
    of ekFunction:
        resolveFunction(r, ex.params, ex.body)
        discard

proc resolveFunction*(r: var Resolver, params: seq[Token], body: seq[Stmt]) =
    let enclosingFunction = r.currentFunction
    r.currentFunction = ftFunction
    beginScope(r)
    for param in params:
        declare(r, param)
        define(r, param)
    for bodyStmt in body:
        resolveStmt(r, bodyStmt)
    endScope(r)
    r.currentFunction = enclosingFunction


proc resolveStmt*(r: var Resolver, st: Stmt) =
    case st.kind:
    of skBlock:
        beginScope(r)
        for stmt in st.statements:
            resolveStmt(r, stmt)
        endScope(r)
    of skVar:
        declare(r, st.name)
        if st.varExpr != nil:
            resolveExpr(r, st.varExpr)
        define(r, st.name)
    of skFunction:
        declare(r, st.funcName)
        define(r, st.funcName)
        resolveFunction(r, st.params, st.funcBody)
    of skExpression:
        resolveExpr(r, st.expression)
    of skPrint:
        resolveExpr(r, st.printExpr)
    of skIf:
        resolveExpr(r, st.condition)
        resolveStmt(r, st.thenBranch)
        if st.elseBranch != nil:
            resolveStmt(r, st.elseBranch)
    of skWhile:
        resolveExpr(r, st.con)
        resolveStmt(r, st.body)
    of skReturn:
        if r.currentFunction == ftNone:
            loxError(st.keyword, "Can't return from top-level code.")
        if st.value != nil:
            resolveExpr(r, st.value)
    of skClass:
        # todo: temp
        declare(r, st.className)
        define(r, st.className)
    of skBreak:
        discard
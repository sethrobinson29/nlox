import std/tables
import ./types
import ./error

proc resolveStmt*(r: var Resolver, st: Stmt)
proc resolveFunction*(r: var Resolver, params: seq[Token], body: seq[Stmt], fnType: FunctionType)

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
        r.resolveLocal(ex, ex.name)
    of ekAssign:
        r.resolveExpr(ex.assignExpr)
        r.resolveLocal(ex, ex.token)
    of ekBinary:
        r.resolveExpr(ex.left)
        r.resolveExpr(ex.right)
    of ekUnary:
        r.resolveExpr(ex.unaryRight)
    of ekGrouping:
        r.resolveExpr(ex.expression)
    of ekLiteral:
        discard
    of ekCall:
        r.resolveExpr(ex.callee)
        for arg in ex.args:
            r.resolveExpr(arg)
    of ekFunction:
        r.resolveFunction(ex.params, ex.body, ftFunction)
    of ekGetProp:
        r.resolveExpr(ex.getPropObj)
    of ekSetProp:
        r.resolveExpr(ex.setPropVal)
        r.resolveExpr(ex.setPropObj)

proc resolveFunction*(r: var Resolver, params: seq[Token], body: seq[Stmt], fnType: FunctionType) =
    let enclosingFunction = r.currentFunction
    r.currentFunction = fnType
    r.beginScope()
    for param in params:
        r.declare(param)
        r.define(param)
    for bodyStmt in body:
        r.resolveStmt(bodyStmt)
    r.endScope()
    r.currentFunction = enclosingFunction


proc resolveStmt*(r: var Resolver, st: Stmt) =
    case st.kind:
    of skBlock:
        r.beginScope()
        for stmt in st.statements:
            resolveStmt(r, stmt)
        r.endScope()
    of skVar:
        r.declare(st.name)
        if st.varExpr != nil:
            r.resolveExpr(st.varExpr)
        r.define(st.name)
    of skFunction:
        r.declare(st.funcName)
        r.define(st.funcName)
        r.resolveFunction(st.params, st.funcBody, ftFunction)
    of skExpression:
        r.resolveExpr(st.expression)
    of skPrint:
        r.resolveExpr(st.printExpr)
    of skIf:
        r.resolveExpr(st.condition)
        r.resolveStmt(st.thenBranch)
        if st.elseBranch != nil:
            r.resolveStmt(st.elseBranch)
    of skWhile:
        r.resolveExpr(st.con)
        r.resolveStmt(st.body)
    of skReturn:
        if r.currentFunction == ftNone:
            loxError(st.keyword, "Can't return from top-level code.")
        if st.value != nil:
            r.resolveExpr(st.value)
    of skClass:
        r.declare(st.className)
        r.define(st.className)

        for m in st.methods:
            r.resolveFunction(m.params, m.funcBody, ftMethod)
    of skBreak:
        discard
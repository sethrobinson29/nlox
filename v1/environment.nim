import std/tables
import ./types
import ./error
    

proc define*(env: var Environment, name: string, val: Literal) =
    env.values[name] = val

proc get*(env: var Environment, token: Token): Literal = 
    if (env.values.hasKey(token.lexeme)):
        return env.values[token.lexeme]

    if (env.enclosing != nil): return env.enclosing.get(token)

    raise newRuntimeError(token, "Undefined variable '" & token.lexeme & "'.")

proc assign*(env: var Environment, token: Token, val: Literal) = 
    if (env.values.hasKey(token.lexeme)):
        env.values[token.lexeme] = val
        return
    if (env.enclosing != nil):
        env.enclosing.assign(token, val)
        return 
    
    raise newRuntimeError(token, "Undefined variable '" & token.lexeme & "'.")


# scope depth
proc getAt*(env: var Environment, depth: int, name: Token): Literal = 
    var curEnv = env
    var curDepth = 0
    while (curEnv != nil):
        if (curDepth == depth):
            return curEnv.get(name)
        curEnv = curEnv.enclosing
        inc curDepth
    raise newRuntimeError(name, "Internal error: resolved depth exceeds environment chain.")

proc assignAt*(env: var Environment, depth: int, name: Token, value: Literal) = 
    var curEnv = env
    var curDepth = 0
    while (curEnv != nil):
        if (curDepth == depth):
            curEnv.assign(name, value)
            return 
        curEnv = curEnv.enclosing
        inc curDepth
    raise newRuntimeError(name, "Internal error: resolved depth exceeds environment chain.")
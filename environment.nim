import std/tables
import ./token
import ./error

type 
    Environment* = ref object
        values*: Table[string, Literal]
        enclosing*: Environment

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
import std/tables
import ./token
import ./error

type 
    Environment* = ref object
        values*: Table[string, Literal]

proc define*(env: var Environment, name: string, val: Literal) =
    env.values[name] = val

proc get*(env: var Environment, token: Token): Literal = 
    if (env.values.hasKey(token.lexeme)):
        return env.values[token.lexeme]

    raise newRuntimeError(token, "Undefined variable '" & token.lexeme & "'.")

proc assign*(env: var Environment, token: Token, val: Literal) = 
    if (env.values.hasKey(token.lexeme)):
        env.values[token.lexeme] = val
    else:
        raise newRuntimeError(token, "Undefined variable '" & token.lexeme & "'.")
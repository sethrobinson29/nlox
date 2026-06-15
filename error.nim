import std/strformat
import ./types

type 
    ParseError* = object of CatchableError 
    RuntimeError* = object of CatchableError
        token*: Token
    BreakException* = object of CatchableError

var hadError*: bool = false
var hadRuntimeError*: bool = false

proc loxReport*(line: int, where: string, message: string) = 
    echo &"[line {line}] Error {where}: {message}"

# scanner error
proc loxError*(line: int, message: string) = 
    loxReport(line, "", message)
    hadError = true

# parser error
proc loxError*(token: Token, message: string) = 
    if (token.tkType == tkEof):
        loxReport(token.line, " at end", message)
    else: 
        loxReport(token.line, " at '" & token.lexeme & "'", message)
    hadError = true

# Nim error
proc systemError*(message: string) = 
    echo "Error: " & message
    hadError = true

# runtime error
proc newRuntimeError*(token: Token, message: string): ref RuntimeError = 
    result = newException(RuntimeError, message)
    result.token = token

proc reportRuntimeError*(error: ref RuntimeError) =
    echo error.msg & "\n[line " & $error.token.line & "]"
    hadRuntimeError = true
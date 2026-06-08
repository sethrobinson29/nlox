import std/strformat
import ./token

type 
    ParseError* = object of CatchableError 

var hadError*: bool = false

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
import std/strformat

var hadError*: bool = false

proc loxReport*(line: int, where: string, message: string) = 
    echo &"[line {line}] Error {where}: {message}"

proc loxError*(line: int, message: string) = 
    loxReport(line, "", message)
    hadError = true

proc systemError*(message: string) = 
    echo "Error: " & message
    hadError = true
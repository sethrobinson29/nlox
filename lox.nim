import std/cmdline
import std/syncio
import strformat

# Error handling
var hadError: bool = false

proc report(line: int, where: string, message: string) = 
    echo &"[line {line}] Error {where}: {message}"

proc error(line: int, message: string) = 
    report(line, "", message)

# Run application
proc run(source: string) = 
    let scanner: Scanner = Scanner()
    let tokens: Token = newSeq[Token]

    for token in tokens:
        echo token

proc runFile(path: string) =
    let source = readFile(path)
    run(source)
    if hadError: quit(65)

# Run REPL
proc runPrompt() = 
    while true:
        stdout.write("> ")
        try:
            let line: string = readLine(stdin)
            if line.len == 0:
                break
            run(line)
            hadError = false
        except EOFError:
            break

# Execute 
when isMainModule:
    if paramCount() > 1:
        echo "Usage: nlox [script]"
        quit(64)
    elif paramCount() == 1:
        runFile(paramStr(1))
    else:
        runPrompt()
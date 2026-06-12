import std/cmdline
import std/syncio
import ./token
import ./exprsn
import ./scanner
import ./parser
import ./interpreter
import ./error

# Run application
proc run(source: string) = 
    var scanner: Scanner = Scanner(source: source)
    let tokens: seq[Token] = scanner.scanTokens()
    var parser: Parser = Parser(tokens: tokens)
    let expression: Expr = parser.parse()

    if hadError: return

    interpret(expression)
    # todo: remove debug outputs
    # echo expression

    # for token in tokens:
    #     echo token

proc runFile(path: string) =
    try:
        let source = readFile(path)
        run(source)
        if hadError: quit(65)
        if hadRuntimeError: quit(70)
    except IOError:
        systemError("Could not read file: " & path)
        quit(74)

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
            hadRuntimeError = false
        except EOFError:
            break
        except IOError:
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
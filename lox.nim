import std/cmdline
import std/syncio
import std/tables
import ./environment
import ./statement
import ./expression
import ./token
import ./scanner
import ./parser
import ./interpreter
import ./error

# Run application
proc run(source: string, env: var Environment) = 
    var scanner: Scanner = Scanner(source: source)
    let tokens: seq[Token] = scanner.scanTokens()
    var parser: Parser = Parser(tokens: tokens)
    let statements: seq[Stmt] = parser.parse()

    if hadError: return

    interpret(statements, env)
    # todo: remove debug outputs
    # echo expression

    # for token in tokens:
    #     echo token

proc runFile(path: string) =
    try:
        let source = readFile(path)
        var env = Environment(values: initTable[string, Literal]())
        run(source, env)
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
            var env = Environment(values: initTable[string, Literal]())
            let line: string = readLine(stdin)
            if line.len == 0:
                break
            run(line, env)
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
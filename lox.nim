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

# keywords that begin statements — skip expression fallback in REPL
const statementKeywords = {tkVar, tkPrint, tkIf, tkWhile, tkFor, tkFun, tkClass, tkReturn}

# Run application
proc run(source: string, env: var Environment, isRepl: bool = false) = 
    var scanner = Scanner(source: source)
    let tokens = scanner.scanTokens()

    if (isRepl):
        # token check avoids parseExpr printing errors on statement keywords before fallback
        let firstToken = tokens[0].tkType
        let startsWithKeyword = firstToken in statementKeywords

        if not startsWithKeyword:
            var exParser = Parser(tokens: tokens)
            let ex = exParser.parseExpr()
            if not hadError and ex != nil:
                interpret(@[newPrintStmt(ex)], env)
                return
            hadError = false

    var parser = Parser(tokens: tokens)
    let statements = parser.parse()

    if hadError: return

    interpret(statements, env)
    # todo: remove debug outputs
    # echo expression

    # for token in tokens:
    #     echo token

proc runFile(path: string) =
    try:
        let source = readFile(path)
        var env = Environment(values: initTable[string, Literal](), enclosing: nil)
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
            run(line, env, true)
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
import std/tables
import ./environment
import ./types
import ./literal
import ./error
import ./function
import ./statement
import ./loxclass

# global scope and definitions
var globals = Environment(values: initTable[string, Literal](), enclosing: nil)

globals.define("clock", initLiteral(initClock()))

proc execute(st: Stmt, env: var Environment)
proc call*(lit: Literal, args: seq[Literal], env: var Environment): Literal

proc isTruthy(litr: Literal): bool = 
    case litr.kind:
    of lkNil: false
    of lkBool: litr.boolVal
    else: true

proc isEqual(left, right: Literal): bool = 
    if left.kind != right.kind: return false
    case left.kind:
    of lkNil: true
    of lkBool: left.boolVal == right.boolVal
    of lkFloat: left.floatVal == right.floatVal
    of lkString: left.strVal == right.strVal
    else:
        #todo
        false

proc checkNumberOperand(op: Token, operand: Literal) =
    if (operand.kind != lkFloat): raise newRuntimeError(op, "Operand must be a number.")

proc checkNumberOperands(op: Token, left: Literal, right: Literal) = 
    if (left.kind != lkFloat or right.kind != lkFloat): raise newRuntimeError(op, "Operands must be numbers.")

proc evaluate*(ex: Expr, env: var Environment): Literal =
    case ex.kind:
    of ekLiteral: ex.value
    of ekGrouping: evaluate(ex.expression, env)
    of ekUnary:
        let right = evaluate(ex.unaryRight, env)

        case (ex.unaryOp.tkType):
        of tkBang: initLiteral(not isTruthy(right))
        of tkMinus: 
            checkNumberOperand(ex.unaryOp, right)
            initLiteral(-right.floatVal)
        else: initLiteral()
    of ekBinary:
        # short circuit for and/or
        if ex.operator.tkType == tkAnd:
            let left = evaluate(ex.left, env)
            if not isTruthy(left): return left
            return evaluate(ex.right, env)
        if ex.operator.tkType == tkOr:
            let left = evaluate(ex.left, env)
            if isTruthy(left): return left
            return evaluate(ex.right, env)

        let left = evaluate(ex.left, env)
        let right = evaluate(ex.right, env)

        case (ex.operator.tkType):
        of tkMinus: 
            checkNumberOperands(ex.operator, left, right)
            initLiteral(left.floatVal - right.floatVal)
        of tkSlash: 
            checkNumberOperands(ex.operator, left, right)
            initLiteral(left.floatVal / right.floatVal)
        of tkStar: 
            checkNumberOperands(ex.operator, left, right)
            initLiteral(left.floatVal * right.floatVal)
        of tkPlus:
            if (left.kind == lkFloat and right.kind == lkFloat): initLiteral(left.floatVal + right.floatVal)
            elif (left.kind == lkString and right.kind == lkString): initLiteral(left.strVal & right.strVal)
            else: raise newRuntimeError(ex.operator, "Operands must be two numbers or two strings.")
        # todo handle type checking?
        of tkGreater: 
            checkNumberOperands(ex.operator, left, right)
            initLiteral(left.floatVal > right.floatVal)
        of tkGreaterEqual: 
            checkNumberOperands(ex.operator, left, right)
            initLiteral(left.floatVal >= right.floatVal)
        of tkLess: 
            checkNumberOperands(ex.operator, left, right)
            initLiteral(left.floatVal < right.floatVal)
        of tkLessEqual: 
            checkNumberOperands(ex.operator, left, right)
            initLiteral(left.floatVal <= right.floatVal)
        of tkBangEqual: initLiteral(not isEqual(left, right))
        of tkEqualEqual: initLiteral(isEqual(left, right))
        else: initLiteral()
    of ekVar:
        if (ex.varDepth == -1):
            env.get(ex.name)
        else:
            env.getAt(ex.varDepth, ex.name)
    of ekAssign:
        let val = evaluate(ex.assignExpr, env)
        if (ex.assignDepth == -1):
            env.assign(ex.token, val)
        else:
            env.assignAt(ex.assignDepth, ex.token, val)
        val
    of ekCall:
        let callee = evaluate(ex.callee, env)
        if callee.kind notin {lkFunction, lkClass}:
            raise newRuntimeError(ex.paren, "Can only call functions and classes.")

        if (ex.args.len != callee.arity()):
            raise newRuntimeError(ex.paren, "Expected " & $callee.arity() & " arguments but got " & $ex.args.len & ".")
        var evaledArgs: seq[Literal]
        for arg in ex.args:
            evaledArgs.add(evaluate(arg, env))
        
        call(callee, evaledArgs, env)
    of ekFunction:
        let tempStmt = Stmt(kind: skFunction, funcName: Token(tkType: tkFun, lexeme: "<anon>", line: 0), params: ex.params, funcBody: ex.body)
        initLiteral(LoxFunction(arity: ex.params.len, kind: lfLox, declaration: tempStmt, closure: env))
    of ekGetProp:
        var obj = evaluate(ex.getPropObj, env)
        if (obj.kind == lkInstance):
            obj.instance.get(ex.getPropName)
        else:
            raise newRuntimeError(ex.getPropName, "Only instances have properties.")
    of ekSetProp:
        var obj = evaluate(ex.setPropObj, env)
        if (obj.kind != lkInstance):
            raise newRuntimeError(ex.setPropName, "Only instances have fields.")

        let val = evaluate(ex.setPropVal, env)

        obj.instance.set(ex.setPropName, val)
        val


proc executeBlock(statements: seq[Stmt], env: var Environment) = 
    for statement in statements:
        execute(statement, env)

proc call*(lit: Literal, args: seq[Literal], env: var Environment): Literal =
    case lit.kind:
    of lkFunction:
        let fn = lit.function
        case fn.kind:
        of lfNative:
            result = fn.nativeFn(args)
        of lfLox:
            result = initLiteral() # handle functions without return statements
            try:
                var callEnv = Environment(enclosing: fn.closure, values: initTable[string, Literal]())
                let params = fn.declaration.params
                for i in 0..<params.len: 
                    callEnv.define(params[i].lexeme, args[i])
                executeBlock(fn.declaration.funcBody, callEnv)
            except ReturnException as e:
                result = e.value # actual return value
    of lkClass:
        # todo: probably need to populate fields
        result = initLiteral(LoxInstance(arity: 0, cls: lit.cls, fields: initTable[string, Literal]()))
    else:
        result = initLiteral()

proc execute(st: Stmt, env: var Environment) = 
    case st.kind:
    of skExpression:
        discard evaluate(st.expression, env)
    of skPrint:
        let val = evaluate(st.printExpr, env)
        echo $val
    of skVar:
        var value = initLiteral()
        if st.varExpr != nil:
            value = evaluate(st.varExpr, env)
        env.define(st.name.lexeme, value)
    of skBlock:
        var blockEnv = Environment(enclosing: env, values: initTable[string, Literal]())
        executeBlock(st.statements, blockEnv)
    of skIf:
        if (isTruthy(evaluate(st.condition, env))):
            execute(st.thenBranch, env)
        elif (st.elseBranch != nil):
            execute(st.elseBranch, env)
    of skWhile:
        try:
            while (isTruthy(evaluate(st.con, env))):
                execute(st.body, env)
        except BreakException:
            discard
    of skBreak:
        raise newException(BreakException, "")
    of skFunction:
        let fn = LoxFunction(arity: st.params.len, kind: lfLox, declaration: st, closure: env)
        env.define(st.funcName.lexeme, initLiteral(fn))
    of skClass:
        env.define(st.className.lexeme, initLiteral())
        var methods = initTable[string, LoxFunction]()
        for m in st.methods:
            let fn = LoxFunction(arity: m.params.len, kind: lfLox, declaration: m, closure: env)
            methods[m.funcName.lexeme] = fn
        let cls = LoxClass(arity: 0, name: st.className.lexeme, methods: methods)
        env.assign(st.className, initLiteral(cls))
    of skReturn:
        let val: Literal = if (st.value != nil): evaluate(st.value, env) else: initLiteral()
        raise newReturnException(val)  

proc interpret*(statements: seq[Stmt], env: var Environment) = 
    try:
        for statement in statements:
            execute(statement, env)
    except RuntimeError as e:
        reportRuntimeError(e)
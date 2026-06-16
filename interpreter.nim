import std/tables
import ./environment
import ./types
import ./literal
import ./error
import ./function

# global scope and definitions
var globals = Environment(values: initTable[string, Literal](), enclosing: nil)

globals.define("clock", initLiteral(initClock()))

proc execute(st: Stmt, env: var Environment)

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
        env.get(ex.name)
    of ekAssign:
        let val = evaluate(ex.assignExpr, env)
        env.assign(ex.token, val)
        val
    of ekCall:
        let callee = evaluate(ex.callee, env)
        if callee.kind notin {lkFunction, lkClass}:
            raise newRuntimeError(ex.paren, "Can only call functions and classes.")

        if (ex.args.len != callee.arity()):
            raise newRuntimeError(ex.paren, "Expected " & $callee.arity() & " arguments but got " & $ex.args.len & ".")
        # todo
        initLiteral()

proc executeBlock(statements: seq[Stmt], env: var Environment) = 
    for statement in statements:
        execute(statement, env)

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
        discard
         

proc interpret*(statements: seq[Stmt], env: var Environment) = 
    try:
        for statement in statements:
            execute(statement, env)
    except RuntimeError as e:
        reportRuntimeError(e)
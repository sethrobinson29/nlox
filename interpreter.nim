import ./statement
import ./expression
import ./token
import ./error

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

proc checkNumberOperand(op: Token, operand: Literal) =
    if (operand.kind != lkFloat): raise newRuntimeError(op, "Operand must be a number.")

proc checkNumberOperands(op: Token, left: Literal, right: Literal) = 
    if (left.kind != lkFloat or right.kind != lkFloat): raise newRuntimeError(op, "Operands must be numbers.")

proc evaluate*(ex: Expr): Literal =
    case ex.kind:
    of ekLiteral: ex.value
    of ekGrouping: evaluate(ex.expression)
    of ekUnary:
        let right = evaluate(ex.unaryRight)

        case (ex.unaryOp.tkType):
        of tkBang: initLiteral(not isTruthy(right))
        of tkMinus: 
            checkNumberOperand(ex.unaryOp, right)
            initLiteral(-right.floatVal)
        else: initLiteral()
    of ekBinary:
        let left = evaluate(ex.left)
        let right = evaluate(ex.right)

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
        initLiteral()


proc execute(st: Stmt) = 
    case st.kind:
    of skExpression:
        discard evaluate(st.expression)
    of skPrint:
        let val = evaluate(st.printExpr)
        echo $val
    of skVar:
        discard

proc interpret*(statements: seq[Stmt]) = 
    try:
        for statement in statements:
            execute(statement)
    except RuntimeError as e:
        reportRuntimeError(e)
# type definitions
import std/tables

type 
    TokenType* = enum
        # single characters
        tkLeftParen, tkRightParen, tkLeftBrace, tkRightBrace,
        tkComma, tkDot, tkMinus, tkPlus, tkSemicolon, tkSlash, tkStar

        # 1 or 2 characters
        tkBang, tkBangEqual, tkEqual, tkEqualEqual, tkGreater,
        tkGreaterEqual, tkLess, tkLessEqual

        # literals
        tkIdentifier, tkString, tkNumber

        # keywords
        tkAnd, tkClass, tkElse, tkFalse, tkFun, tkFor,
        tkIf, tkNil, tkOr, tkPrint, tkReturn, tkSuper,
        tkThis, tkTrue, tkVar, tkWhile, tkBreak

        tkEof
        
    Token* = object
        tkType*: TokenType
        lexeme*: string
        literal*: Literal
        line*: int

    LiteralKind* = enum
        lkNil, lkBool, lkFloat, lkString, lkFunction, lkClass, lkInstance

    Literal* = object
        case kind*: LiteralKind
        of lkNil: discard
        of lkBool: boolVal*: bool
        of lkFloat: floatVal*: float
        of lkString: strVal*: string
        of lkFunction: function*: LoxFunction
        of lkClass: cls*: LoxClass
        of lkInstance: instance*: LoxInstance

    ExprKind* = enum
        ekBinary, ekUnary, ekLiteral, ekGrouping, ekVar, ekAssign, ekCall, ekFunction

    Expr* = ref object
        case kind*: ExprKind
        of ekBinary:
            left*: Expr
            operator*: Token
            right*: Expr
        of ekUnary:
            unaryOp*: Token
            unaryRight*: Expr
        of ekLiteral:
            value*: Literal
        of ekGrouping:
            expression*: Expr
        of ekVar:
            name*: Token
            varDepth*: int = -1
        of ekAssign:
            token*: Token
            assignExpr*: Expr
            assignDepth*: int = -1
        of ekCall:
            callee*: Expr
            paren*: Token
            args*: seq[Expr]
        of ekFunction:
            params*: seq[Token]
            body*: seq[Stmt]

    StmtKind* = enum 
        skExpression, skPrint, skVar, skBlock, skIf, skWhile, skBreak, skFunction, skReturn

    Stmt* = ref object
        case kind*: StmtKind
        of skExpression: 
            expression*: Expr
        of skPrint:
            printExpr*: Expr
        of skVar:
            name*: Token
            varExpr*: Expr
        of skBlock:
            statements*: seq[Stmt]
        of skIf:
            condition*: Expr
            thenBranch*: Stmt
            elseBranch*: Stmt
        of skWhile:
            con*: Expr
            body*: Stmt
        of skBreak:
            discard
        of skFunction:
            funcName*: Token
            params*: seq[Token]
            funcBody*: seq[Stmt]
        of skReturn:
            keyword*: Token
            value*: Expr

    Environment* = ref object
        values*: Table[string, Literal]
        enclosing*: Environment

    FunctionType* = enum ftNone, ftFunction

    Resolver* = object
        scopes*: seq[Table[string, bool]]
        currentFunction*: FunctionType

    LoxFunctionKind* = enum lfLox, lfNative

    LoxFunction* = ref object
        arity*: int
        case kind*: LoxFunctionKind
        of lfLox:
            declaration*: Stmt 
            closure*: Environment
        of lfNative:
            nativeFn*: proc(args: seq[Literal]): Literal

    LoxClass* = ref object
        arity*: int
        name*: string
        # methods etc later

    LoxInstance* = ref object
        arity*: int
        klass*: LoxClass
        fields*: Table[string, Literal]
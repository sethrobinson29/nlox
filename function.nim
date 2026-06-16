# function functionality
import std/times
import ./types
import./literal

# native functions
proc clockNative(args: seq[Literal]): Literal =
    initLiteral(epochTime())

proc initClock*(): LoxFunction = LoxFunction(arity: 0, kind: lfNative, nativeFn: clockNative)

# function procs
proc arity*(lit: Literal): int =
    case lit.kind:
    of lkFunction: lit.function.arity
    of lkClass: 0  # todo: init method later
    else: 0

proc call*(lit: Literal, args: seq[Literal]): Literal =
    case lit.kind:
    of lkFunction:
        let fn = lit.function
        case fn.kind:
        of lfNative:
            fn.nativeFn(args)
        of lfLox:
            # create new environment with closure as enclosing
            # bind params to args
            # executeBlock with function body
            # return value (need a way to handle return — chapter 10 covers this)
            initLiteral()  # placeholder
    else:
        initLiteral()
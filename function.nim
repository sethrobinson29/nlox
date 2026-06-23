# function functionality
import std/times
import ./types
import ./literal

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
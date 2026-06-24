# function functionality
import std/times
import ./types
import ./literal

# native functions
proc clockNative(args: seq[Literal]): Literal =
    initLiteral(epochTime())

proc initClock*(): LoxFunction = LoxFunction(arity: 0, kind: lfNative, nativeFn: clockNative)


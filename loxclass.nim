import std/tables
import ./types
import ./error
import ./literal
import ./environment

proc bindInstance*(inst: LoxInstance, mthd: LoxFunction): LoxFunction

# class procs
proc findMethod*(cls: LoxClass, name: string): LoxFunction = 
    if (cls.methods.hasKey(name)):
        result = cls.methods[name] 
    elif (cls.superClass.kind == lkClass):
        result = cls.superClass.cls.findMethod(name) 
    else: 
        result = nil

# instance procs
proc get*(inst: LoxInstance, name: Token): Literal = 
    if (inst.fields.hasKey(name.lexeme)):
        return inst.fields[name.lexeme]
    let mthd = inst.cls.findMethod(name.lexeme)
    if (mthd != nil):
        return initLiteral(inst.bindInstance(mthd))
    raise newRuntimeError(name, "Undefined property '" & name.lexeme & "'.")

proc set*(inst: LoxInstance, name: Token, value: Literal) =
    inst.fields[name.lexeme] = value

proc bindInstance*(inst: LoxInstance, mthd: LoxFunction): LoxFunction = 
    var env = Environment(enclosing: mthd.closure, values: initTable[string, Literal]())
    env.define("this", initLiteral(inst))
    LoxFunction(arity: mthd.arity, kind: lfLox, declaration: mthd.declaration, closure: env) 

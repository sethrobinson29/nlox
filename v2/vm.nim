import ./chunk
import ./value

type 
    VM* = object
        chunk*: ptr Chunk
        ip: ptr uint8

    InterpretResult = enum 
        INTERPRET_OK, INTERPRET_COMPILE_ERROR, INTERPRET_RUNTIME_ERROR

var vm* = VM()

proc initVM*() = 
    discard

proc freeVM*() =
    discard

# helpers for run (defined as macros in the book)
proc readByte(): uint8 = 
    result = vm.ip[]
    inc vm.ip

proc readConstant(): Value = 
    vm.chunk.constants.values[readByte()]

proc run*(): InterpretResult =
    while (true):
        let instruction = readByte()
        case OpCode(instruction):
        of OP_RETURN:
            return INTERPRET_OK
        of OP_CONSTANT:
            let constant = readConstant()
            echo $constant
            break

proc interpret*(ch: ptr Chunk): InterpretResult = 
    vm.chunk = ch
    vm.ip = cast[ptr uint8](vm.chunk[].code)
    run()
import ./memory
import ./value

type
    OpCode* = enum 
        OP_CONSTANT, OP_RETURN

    Chunk* = object
        count*: int
        capacity*: int
        code*: ptr UncheckedArray[uint8]
        constants*: ValueArray
        lines*: ptr UncheckedArray[int]

proc initChunk*(ch: var Chunk) = 
    ch.count = 0
    ch.capacity = 0
    ch.code = nil
    ch.lines = nil
    initValueArray(ch.constants)

proc writeChunk*(ch: var Chunk, b: uint8, line: int) = 
    if (ch.capacity < ch.count + 1):
        let oldCapacity = ch.capacity
        ch.capacity = growCapacity(oldCapacity)
        ch.code = growArray(ch.code, oldCapacity, ch.capacity)
        ch.lines = growArray(ch.lines, oldCapacity, ch.capacity)

    ch.code[ch.count] = b
    ch.lines[ch.count] = line
    inc ch.count

proc freeChunk*(ch: var Chunk) = 
    freeArray(ch.code, ch.capacity)
    freeValueArray(ch.constants)
    freeArray(ch.lines, ch.capacity)
    initChunk(ch)

proc addConstant*(ch: var Chunk, val: Value): int  =
    writeValueArray(ch.constants, val)
    ch.constants.count - 1
import ./memory

type
    OpCode = enum OP_RETURN

    Chunk = object
        count: int
        capacity: int
        code: ptr UncheckedArray[uint8]


proc initChunk(ch: var Chunk) = 
    ch.count = 0
    ch.capacity = 0
    ch.code = nil

proc writeChunk(ch: var Chunk, b: uint8) = 
    if (ch.capacity < ch.count + 1):
        let oldCapacity = ch.capacity
        ch.capacity = growCapacity(oldCapacity)
        ch.code = growArray(ch.code, oldCapacity, ch.capacity)

    ch.code[ch.count] = b
    inc ch.count

proc freeChunk(ch: var Chunk) = 
    freeArray(ch.code, ch.capacity)
    initChunk(ch)
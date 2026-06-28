import ./chunk
import ./vm
import ./value # todo: maybe remove?
import ./debug

# Execute 
when isMainModule:
    initVM()

    var ch: Chunk
    initChunk(ch)

    # temp hand-compiled instruction
    let constant1 = addConstant(ch, Value(kind: valNumber, number: 1.2))
    writeChunk(ch, uint8(OP_CONSTANT), 1)
    writeChunk(ch, uint8(constant1), 1)
    let constant2 = addConstant(ch, Value(kind: valNumber, number: 2.1))
    writeChunk(ch, uint8(OP_CONSTANT), 1)
    writeChunk(ch, uint8(constant2), 1)

    writeChunk(ch, uint8(OP_RETURN), 3)
    disassembleChunk(ch, "test chunk")
    interpret(ch)
    freeVM()
    freeChunk(ch)

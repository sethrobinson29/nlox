import strutils
import ./chunk
import ./value

proc simpleInstruction(name: string, offset: int): int = 
    echo name & "\n"
    offset + 1

proc constantInstruction(name: string, ch: Chunk, offset: int): int = 
    let constant = ch.code[offset+1]
    stdout.write(name.alignLeft(16) & " " & ($constant).align(4) & " ")
    echo ch.constants.values[constant]
    offset + 2

proc disassembleInstruction(ch: var Chunk, offset: int): int = 
    stdout.write(intToStr(offset).align(4, '0') & " ")

    if (offset > 0 and ch.lines[offset] == ch.lines[offset - 1]):
        stdout.write("   | ")
    else:
        stdout.write(intToStr(ch.lines[offset]).align(4) & " ")

    let instruction = ch.code[offset]
    case OpCode(instruction):
    of OP_CONSTANT:
        constantInstruction("OP_CONSTANT", ch, offset)
    of OP_RETURN:
        simpleInstruction("OP_RETURN", offset)
    else:
        echo "Unknown opcode " & $instruction & "\n"
        offset + 1

proc disassembleChunk*(ch: var Chunk, name: string) = 
    echo "== " & name & " ==\n"

    var offset = 0
    while offset < ch.count:
        offset = disassembleInstruction(ch, offset)
    
import ./memory

type
    ValueKind* = enum
        valNil, valBool, valNumber

    Value* = object
        case kind*: ValueKind
        of valBool: 
            boolean*: bool
        of valNumber: 
            number*: float64
        of valNil: 
            discard

    ValueArray* = object
        capacity*: int
        count*: int
        values*: ptr UncheckedArray[Value]

proc `$`*(val: Value): string = 
    case val.kind:
    of valNumber:
        $val.number
    of valBool:
        $val.boolean
    else: 
        ""

proc initValueArray*(arr: var ValueArray) = 
    arr.values = nil
    arr.capacity = 0
    arr.count = 0

proc writeValueArray*(arr: var ValueArray, val: Value) = 
    if (arr.capacity < arr.count + 1):
        let oldCapacity = arr.capacity
        arr.capacity = growCapacity(oldCapacity)
        arr.values = growArray(arr.values, oldCapacity, arr.capacity)

    arr.values[arr.count] = val
    inc arr.count

proc freeValueArray*(arr: var ValueArray) = 
    freeArray(arr.values, arr.capacity)
    initValueArray(arr)
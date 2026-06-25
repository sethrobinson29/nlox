proc growCapacity*(curCapacity: int): int = 
    if (curCapacity < 8): 8 else: (curCapacity * 2)

proc reallocate[T](p: ptr UncheckedArray[T], oldSize, newSize: int): pointer = 
    if (newSize == 0):
        dealloc(p)
        return nil
    result = realloc(p, newSize)
    if (result == nil): quit(1)

proc growArray*[T](p: ptr UncheckedArray[T], oldCount, newCount: int): ptr UncheckedArray[T] =
    cast[ptr UncheckedArray[T]](reallocate(p, (oldCount * sizeof(T)), (newCount * sizeof(T))))

proc freeArray*[T](p: ptr UncheckedArray[T], oldCount: int) = 
    discard reallocate(p, (sizeof(T) * oldCount), 0)
# translation-notes.md — nlox v2 (Bytecode VM)

C-to-Nim translation notes for Part III of *Crafting Interpreters*.

---

## Quick Reference

| C pattern | Nim equivalent | Notes |
|---|---|---|
| Tagged union (`ValueType` + `union`) | `object variants` (case object) | Few kinds, small payloads — less friction than v1 |
| `uint8_t*` dynamic array + count/capacity | `ptr UncheckedArray[T]` + manual alloc | `ptr uint8` addresses one byte; `UncheckedArray` enables `[]` indexing. Deliberate; see Memory below |
| `GROW_ARRAY` / `FREE_ARRAY` macros | Generic `growArray` / `freeArray` procs | |
| `#define` macros (non-generic) | `template` | Use procs when type matters |
| Global `VM` struct | Module-level `var vm: VM` | Matches book structure |

---

## Deep Dives

### Memory Management

Rather than replacing the book's manual allocation with `seq`, we replicate it using Nim's `alloc0`, `realloc`, and `dealloc`. ARC has no visibility into manually allocated memory — every allocation needs a corresponding `dealloc`.

Raw buffers are typed via `cast[ptr UncheckedArray[T]]` to enable `[]` indexing:

```nim
proc growArray[T](p: ptr UncheckedArray[T], oldCount, newCount: int): ptr UncheckedArray[T] =
  cast[ptr UncheckedArray[T]](realloc(p, oldCount * sizeof(T), newCount * sizeof(T)))
```

Prefer `alloc0` for new buffers — it zero-initializes. `realloc` does not zero the extended region.

---

### Value Representation

The book's `Value` tagged union becomes an object variant:

```nim
type
  ValueKind = enum
    valNil, valBool, valNumber

  Value = object
    case kind: ValueKind
    of valBool: boolean: bool
    of valNumber: number: float64
    of valNil: discard
```

The book's accessor macros (`AS_NUMBER`, `IS_BOOL`, etc.) become inline procs or are inlined at call sites. A `valObj` branch will be added when heap-allocated objects arrive.
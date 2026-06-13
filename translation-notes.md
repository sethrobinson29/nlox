# Java → Nim: Translation Notes for nlox

Recurring differences between jlox (*Crafting Interpreters*, Java) and this
Nim port. Helps explain why the structure diverges even when the logic is the
same.

## No implicit `this`

Java methods implicitly access `this`. Nim has no implicit receiver — every
proc takes the object it operates on as an explicit first parameter:

```nim
proc advance(s: var Scanner): char =
  result = s.source[s.current]
  inc s.current
```

UFCS lets you *call* this as `s.advance()`, but the definition always has an
explicit receiver — no `self`/`this` inside the body.

**Effect:** when one private method calls another in the book, every call in
the chain needs the object passed through explicitly.

## `object` / `ref object` vs class

Java only has classes. Nim splits this up:

- **`object`** — value type (like a C struct), copied on assignment. Used for
  `Token`, `Literal`, `Scanner`, `Parser`, `Environment`.
- **`ref object`** — heap-allocated reference type. Used for `Expr`/`Stmt`
  since AST nodes form a tree of pointers to each other.
- **`ref object of RootObj`** — adds inheritance. **Not used here** (see
  below).

No "class" keyword, no constructors/methods bound to the type — procs are
associated only by convention (same file, object as first param).

## Variant objects instead of inheritance + visitor

The book's `Expr`/`Stmt` are class hierarchies (one subclass per node type),
and operations over them (`AstPrinter`, `Interpreter`) use the **visitor
pattern** — double dispatch via `accept()`/`visitXyz()` — to work around
Java's lack of sum types.

Nim has sum types natively: variant objects (`case` inside an `object`).

```nim
type
  ExprKind* = enum
    ekBinary, ekUnary, ekLiteral, ekGrouping, ekVar

  Expr* = ref object
    case kind*: ExprKind
    of ekBinary:
      left*: Expr
      operator*: Token
      right*: Expr
    of ekUnary:
      unaryOp*: Token
      unaryRight*: Expr
    of ekLiteral:
      value*: Literal
    of ekGrouping:
      expression*: Expr
    of ekVar:
      name*: Token
```

Any operation is one recursive proc with `case expr.kind` — no `accept`, no
visitor interface, no `GenerateAst.java` step.

**Effect:** a new `visitXyzExpr`/`visitXyzStmt` method in the book becomes a
new `of ekXyz:`/`of skXyz:` branch in the relevant `case`.

**Tradeoff:** all `of` branches share one field namespace. Fields that would
be independently named in separate Java subclasses (`Unary.right` vs.
`Binary.right`, `Expression.expression` vs. `Print.expression`) need distinct
names across variants — `unaryRight`/`right`, `printExpr`/`expression`,
`varExpr`/`expression`, etc. Main verbosity cost vs. inheritance, but
compiler-enforced and arguably clearer at call sites.

## Named constructors instead of overloading

`Literal`'s variants are distinguished by *type* (`bool`/`float`/`string`), so
one overloaded `initLiteral` works — Nim picks the variant from the argument
type:

```nim
proc initLiteral*(s: string): Literal = Literal(kind: lkString, strVal: s)
proc initLiteral*(b: bool): Literal = Literal(kind: lkBool, boolVal: b)
proc initLiteral*(f: float): Literal = Literal(kind: lkFloat, floatVal: f)
proc initLiteral*(): Literal = Literal(kind: lkNil)
```

`Expr`/`Stmt` variants often share argument *types* (e.g. `skExpression` and
`skPrint` both wrap an `Expr`), so overloading would be ambiguous. These get
named constructors instead, one per variant:

```nim
proc newBinary*(left: Expr, op: Token, right: Expr): Expr =
  Expr(kind: ekBinary, left: left, operator: op, right: right)

proc newExpressionStmt*(ex: Expr): Stmt =
  Stmt(kind: skExpression, expression: ex)

proc newPrintStmt*(ex: Expr): Stmt =
  Stmt(kind: skPrint, printExpr: ex)
```

## `Object` → `Literal`

Java uses `Object` (+ autoboxing) as the universal runtime value for Lox's
dynamic typing. Nim equivalent is an explicit variant object:

```nim
type
  LiteralKind* = enum
    lkNil, lkBool, lkFloat, lkString

  Literal* = object
    case kind*: LiteralKind
    of lkNil: discard
    of lkBool: boolVal*: bool
    of lkFloat: floatVal*: float
    of lkString: strVal*: string
```

Used both for token literals (scanner output) and runtime values (`evaluate`
result, `Environment` storage). Anywhere the book says `Object`, this codebase
uses `Literal`.

**Effect:** things Java gets free via inheritance (`equals()`, `toString()`,
`instanceof`) are hand-written `case`-based procs (`isEqual`, `$`,
`isTruthy`), one branch per `LiteralKind`. More verbose, but
exhaustiveness-checked.

## `null` → `nil`, only for `ref` types

Nim's `nil` is only valid for `ref` types, not `object` value types.

- `Literal` (`object`) — **no `nil` Literal**. Lox `nil` is
  `Literal(kind: lkNil)`, via `initLiteral()`.
- `Expr`/`Stmt` (`ref object`) — `nil` works like Java's `null`, e.g. an
  absent `var` initializer:

  ```nim
  var initializer: Expr = nil
  if p.match(tkEqual):
    initializer = p.expression()
  ```

  Anything consuming such a field must check `!= nil` before recursing into
  `evaluate`/`execute`, or it crashes (`FieldDefect`) — same risk as a missing
  Java null-check, different failure shape.

## Exceptions: `error()` returns rather than throws

The book's `Parser.error()` *returns* a `ParseError` rather than throwing,
letting the caller decide whether to unwind:

```nim
proc parseError(p: var Parser, message: string): ref ParseError =
  loxError(p.peek(), message)
  result = newException(ParseError, message)
```

```nim
raise p.parseError("Expect expression.")        # unwind
discard p.parseError("Some non-fatal issue.")   # report only, keep going
```

`ParseError`/`RuntimeError` are `object of CatchableError` in `error.nim`,
alongside `hadError`/`hadRuntimeError` flags and reporting procs (`loxReport`,
`loxError`, `reportRuntimeError`). `RuntimeError` carries `token*: Token` (via
`newRuntimeError`) for line-number reporting.

A third variant — report without constructing/raising anything — shows up in
`assignment()`. The book's invalid-assignment-target error reports via
`error(equals, "...")` but doesn't throw; parsing continues:

```nim
if ex.kind == ekVar:
  return newAssignment(ex.name, val)

loxError(equals, "Invalid assignment target.")
```

`loxError(Token, string)` reports and sets `hadError`, returns nothing — no
`raise`/`discard` needed.

## Enums need exhaustive `case`

Every `case` over `ExprKind`/`StmtKind`/etc. must cover every value (or use
`else`). Adding a variant (`ekVar`, `skVar`, ...) makes every *existing*
`case` over that enum non-exhaustive — AST printer, `evaluate`, `execute`, etc.
all need a new branch, even a placeholder:

```nim
of ekVar:
  initLiteral()  # todo: environment lookup
```

A compiler-enforced checklist with no Java equivalent (a missing
`visitVariableExpr` override also wouldn't compile, but for a different
reason — unimplemented abstract method).

## Export markers (`*`)

No `public`/`private`. Anything (type, proc, field, enum variant, `const`)
private to its module unless suffixed `*`. No equivalent of `final` — a plain
`object` is simply outside any inheritance hierarchy, same practical effect.

- Enum **type** needs `*` (`TokenType*`); individual values don't.
- Variant discriminator fields (`Literal.kind*`) need `*` if matched on from
  another module.
- `discard` branches (`of lkNil: discard`) aren't declarations, never take
  `*`.

## `var` and mutation

Any proc that mutates fields through its object parameter needs `var T`, even
for `ref object` — the reference itself isn't "enough." If a proc does
`env.values[name] = value`, its `env` param needs `var Environment`, and that
propagates up the whole call chain.

Read-only (`peek`, `check`, `get`) — no `var`. Mutating (`advance`, `match`,
`define`, `assign`) — `var`.

This propagates to the original binding too. `Environment` is created once in
`lox.nim` and threaded through `run` → `interpret` → `execute`/`evaluate`.
Since that chain calls `define`/`assign`, the top-level binding must be `var`:

```nim
var env = Environment(values: initTable[string, Literal]())
```

A `let env = ...` only fails once something downstream tries to mutate it —
the error surfaces at the call site needing `var`, not at the declaration.

## `Table` construction: `initTable` vs `newTable`

Java's `Map` is always reference-typed. `std/tables` splits this:

- **`Table[K, V]`** — value type, via `initTable[K, V]()`. Used for
  `Environment.values`.
- **`TableRef[K, V]`** — reference type, via `newTable[K, V]()`.

```nim
type Environment* = object
  values: Table[string, Literal]

var env = Environment(values: initTable[string, Literal]())
```

`newTable`/`TableRef` only needed if `values` itself had to be independently
shared as a reference — not the case here.

## File organization

| File | Contents | Java equivalent |
|---|---|---|
| `token.nim` | `TokenType`, `LiteralKind`, `Literal`, `Token`, constructors, `$` | `TokenType.java`, `Token.java` |
| `error.nim` | error flags, `ParseError`, `RuntimeError`, reporting procs | error bits of `Lox.java` |
| `scanner.nim` | `Scanner` + lexing procs | `Scanner.java` |
| `exprsn.nim` | `Expr` variant object, constructors, AST printer `$` | `Expr.java` (generated) + `AstPrinter.java` |
| `stmt.nim` | `Stmt` variant object, constructors | `Stmt.java` (generated) |
| `parser.nim` | `Parser` + parsing procs | `Parser.java` |
| `environment.nim` | `Environment` (name → `Literal` table) | `Environment.java` |
| `interpreter.nim` | `evaluate`/`execute`/`interpret` (free procs) | `Interpreter.java` |
| `lox.nim` | entry point, `run`/`runFile`/`runPrompt` | `Lox.java` |

Notably absent: `GenerateAst.java` equivalent (variant objects are short
enough to write by hand) and any `Visitor`/`Accept` interfaces.
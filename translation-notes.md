# Java → Nim: Translation Notes for nlox

This document collects the recurring differences between the Java reference
implementation (jlox, from *Crafting Interpreters*) and this Nim port. It's
meant to help anyone following along with the book while reading this codebase
understand *why* the structure diverges from the source material, even when
the underlying logic is the same.

## No implicit `this` / no methods

Java methods are called on an instance (`scanner.scanTokens()`) with implicit
access to the instance's fields via `this`. Nim has no implicit receiver —
every proc that needs to read or mutate an object's state takes that object as
an explicit first parameter.

```nim
proc advance(s: var Scanner): char =
  result = s.source[s.current]
  inc s.current
```

Thanks to Uniform Call Syntax (UFCS), this can still be *called* as
`s.advance()`, which reads like a method call — but the *definition* always
has the explicit receiver. There is no `this`/`self` inside the proc body;
every field access is `s.something`.

**Practical effect:** anywhere the book's class has a private helper method
that calls other private helper methods, every one of those calls in Nim needs
the object passed through explicitly, all the way down the call chain.

## `object` vs ref object vs class

Java only has classes (reference types with inheritance and methods bolted
on). Nim splits this into more primitive pieces:

- **`object`** — a value type (like a C struct). Copied on assignment. Used
  for `Token`, `Literal`, `Scanner`, `Parser`, `Environment` (where it does
  not need to be shared by reference).
- **`ref object`** — a heap-allocated reference type. Used for `Expr` and
  `Stmt`, since AST nodes form a tree of objects that reference each other and
  need pointer/reference semantics, not value-copy semantics.
- **`ref object of RootObj`** — supports inheritance, used by Java's
  `Expr`/`Stmt` class hierarchies. **Not used in this codebase** — see
  "Variant objects instead of inheritance" below.

There is no "class" keyword and no implicit instantiation — `object`/`ref
object` are just data layout declarations. Behavior (procs) is defined
separately and associated only by convention (same file, same parameter
type).

## Variant objects instead of inheritance + visitor pattern

The book's `Expr` and `Stmt` are abstract classes with one subclass per node
type (`Expr.Binary`, `Expr.Unary`, `Expr.Literal`, etc.), and operations over
them (`AstPrinter`, `Interpreter`) are implemented via the **visitor pattern**
— each subclass has an `accept()` method that does double-dispatch into
`visitXyz()` methods.

This entire apparatus exists to work around Java's lack of pattern matching /
sum types. Nim has sum types natively via **variant objects** (`case` inside
an `object`):

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

Any operation over `Expr` (printing, evaluating, etc.) is a single recursive
proc with a `case expr.kind` — no `accept`, no visitor interface, no
`GenerateAst.java`-style code generation step. What the book spends a full
chapter building (the visitor infrastructure) is just a language feature here.

**Practical effect:** when the book introduces a new `visitXyzExpr` /
`visitXyzStmt` method on `Interpreter`/`Resolver`/etc., the Nim translation is
just a new `of ekXyz:` / `of skXyz:` branch in the relevant `case` statement.

**Tradeoff:** all `of` branches share one field namespace, so fields that
would naturally have the same name in separate Java subclasses (e.g.
`Unary.right` and `Binary.right`, or `Expression.expression` and
`Print.expression`) must be given distinct names across variants
(`unaryRight`/`right`, `printExpr`/`expression`, `varExpr`/`expression`,
etc.). This is the main verbosity cost of variant objects relative to
inheritance — though it's compiler-enforced and arguably makes call sites
less ambiguous about which variant a field belongs to.

## Named constructors instead of overloading

`Literal` has variants distinguished by *type* (`bool`, `float`, `string`),
so a single overloaded `initLiteral` works — Nim picks the right variant based
on the argument's type:

```nim
proc initLiteral*(s: string): Literal = Literal(kind: lkString, strVal: s)
proc initLiteral*(b: bool): Literal = Literal(kind: lkBool, boolVal: b)
proc initLiteral*(f: float): Literal = Literal(kind: lkFloat, floatVal: f)
proc initLiteral*(): Literal = Literal(kind: lkNil)
```

`Expr`/`Stmt` variants are *not* distinguishable this way — e.g. both
`skExpression` and `skPrint` wrap a single `Expr`, so an overloaded
`initStmt(expr: Expr)` would be ambiguous. These use **named constructors**
instead, one per variant:

```nim
proc newBinary*(left: Expr, op: Token, right: Expr): Expr =
  Expr(kind: ekBinary, left: left, operator: op, right: right)

proc newExpressionStmt*(ex: Expr): Stmt =
  Stmt(kind: skExpression, expression: ex)

proc newPrintStmt*(ex: Expr): Stmt =
  Stmt(kind: skPrint, printExpr: ex)
```

## `Object` → `Literal`

Java uses `Object` as the universal runtime value type for anything that could
be `nil`, a `Boolean`, a `Double`, or a `String` (Lox's dynamic typing riding
on Java's reference types + autoboxing). Nim has no such universal type —
instead there's an explicit variant object:

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

This is used both for **token literals** (what the scanner produces for
number/string tokens) and **runtime values** (what `evaluate` returns, what
gets stored in `Environment`). Anywhere the book writes `Object`, this
codebase uses `Literal`.

**Practical effect:** operations Java gets "for free" via inheritance —
`equals()`, `toString()`, type checks via `instanceof` — must be hand-written
as `case`-based procs (`isEqual`, `$`, `isTruthy`, etc.), one branch per
`LiteralKind`. More verbose than Java's polymorphism, but exhaustiveness is
compiler-checked.

## `null` → `nil`, and only for `ref` types

Java's `null` is a valid value for any reference type. Nim's `nil` is only
valid for `ref` types (and a few others like pointers) — **not** for `object`
value types. This matters specifically for:

- `Literal` (an `object`, not `ref`) — there is **no `nil` Literal**. "Lox
  nil" is represented as `Literal(kind: lkNil)`, constructed via
  `initLiteral()`.
- `Expr`/`Stmt` (both `ref object`) — `nil` is valid and used the same way
  Java uses `null`, e.g. an optional initializer expression on a `var`
  declaration with no `=`:

  ```nim
  var initializer: Expr = nil
  if p.match(tkEqual):
    initializer = p.expression()
  ```

  Anything that later consumes this field must check `!= nil` before
  recursing into `evaluate`/`execute`, or it will crash (`FieldDefect` /
  nil dereference) — same risk as forgetting a `null` check in Java, just a
  different runtime error shape.

## Exceptions: `error()` returns rather than throws

The book's `Parser.error()` *returns* a `ParseError` rather than throwing it,
so the caller can decide whether to `throw` (unwind) or just log and continue.
This translates directly:

```nim
proc parseError(p: var Parser, message: string): ref ParseError =
  loxError(p.peek(), message)
  result = newException(ParseError, message)
```

Callers choose:

```nim
raise p.parseError("Expect expression.")   # unwind
discard p.parseError("Some non-fatal issue.")  # report only, keep going
```

Custom exception types (`ParseError`, `RuntimeError`) are defined as
`object of CatchableError` in `error.nim`, alongside the shared error-state
flags (`hadError`, `hadRuntimeError`) and reporting procs (`loxReport`,
`loxError`, `reportRuntimeError`). `RuntimeError` additionally carries a
`token*: Token` field (via `newRuntimeError`) so the top-level handler can
report the line number, mirroring the book's `RuntimeError` subclass.

## Enums need exhaustive `case`

Nim's `case` over an enum (or a variant object's discriminator field) must
cover every enum value, either explicitly or via `else`. Every time a new
`ExprKind` / `StmtKind` / `TokenType` variant is added (e.g. `ekVar`,
`skVar`), **every existing `case` over that enum** (the AST printer's `$`,
`evaluate`, `execute`, etc.) becomes non-exhaustive and needs a new branch —
even if it's just a placeholder:

```nim
of ekVar:
  initLiteral()  # todo: environment lookup
```

This is a compile-time-enforced checklist for "did I handle the new node type
everywhere?" — there's no equivalent enforcement in the Java version (a
missing `visitVariableExpr` override just wouldn't compile *either*, but for a
different reason — an abstract method left unimplemented).

## Export markers (`*`)

Nim has no `public`/`private` keywords. A symbol (type, proc, field, enum
variant, `const`, etc.) is private to its defining module unless suffixed with
`*`. There is **no equivalent of Java's `final`** — a plain `object` (vs. `ref
object of RootObj`) is simply not part of any inheritance hierarchy, which has
the same practical effect as `final` for these purposes.

Notes specific to this codebase:

- Enum **type** needs `*` (e.g. `TokenType*`) for the type and all its values
  to be usable elsewhere — individual enum **values** do not need their own
  `*`.
- Variant object discriminator fields (e.g. `Literal`'s `kind*`) need `*` if
  external code pattern-matches on them (`case lit.kind` from another
  module).
- `discard` branches in variant objects (e.g. `of lkNil: discard`) are not
  declarations and never take `*`.

## `var` parameters and mutation

Nim requires `var T` (not just `T`) on any parameter whose fields get mutated
through it — this applies even to `ref object` types, where you might expect
the reference itself to be "enough." If a proc calls `env.values[name] =
value` (mutating a `Table` field), its `env` parameter must be declared `var
Environment`, and that requirement propagates up the call chain to every
caller.

Read-only procs (`peek`, `check`, `get`) do not need `var`. Procs that mutate
(`advance`, `match`, `define`) do.

## File organization

Roughly:

| File | Contents | Java equivalent |
|---|---|---|
| `token.nim` | `TokenType`, `LiteralKind`, `Literal`, `Token`, constructors, `$` | `TokenType.java`, `Token.java` |
| `error.nim` | `hadError`, `hadRuntimeError`, `ParseError`, `RuntimeError`, reporting procs | error-handling bits of `Lox.java` |
| `scanner.nim` | `Scanner` object + lexing procs | `Scanner.java` |
| `exprsn.nim` | `Expr` variant object, constructors, AST printer `$` | `Expr.java` (generated) + `AstPrinter.java` |
| `stmt.nim` | `Stmt` variant object, constructors | `Stmt.java` (generated) |
| `parser.nim` | `Parser` object + parsing procs | `Parser.java` |
| `environment.nim` | `Environment` object (name → `Literal` table) | `Environment.java` |
| `interpreter.nim` | `evaluate`, `execute`, `interpret` (free procs, no `Interpreter` type) | `Interpreter.java` |
| `lox.nim` | entry point, `run`/`runFile`/`runPrompt` | `Lox.java` |

Notably **absent**: anything corresponding to `GenerateAst.java` (no code
generation needed — variant objects are written by hand and are short enough
not to need generation) and any `Visitor`/`Accept` interfaces.
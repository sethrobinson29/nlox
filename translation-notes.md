# Java → Nim: Translation Notes for nlox

Recurring differences between jlox (*Crafting Interpreters*, Java) and this
Nim port. Quick-reference table below; deep dives for anything that needs
more than a row.

## Quick reference

| Java | Nim | Why |
|---|---|---|
| `this` (implicit) | explicit object as first param | no implicit receiver; `s.advance()` works via UFCS but the definition still takes `s` explicitly |
| class | `object` (value) / `ref object` (reference) | Nim splits "class" into value vs. reference types; no inheritance unless `of RootObj` |
| class hierarchy + visitor pattern | variant object (`case` in `object`) | Nim has sum types natively — see [Variant objects](#variant-objects-instead-of-inheritance--visitor) |
| overloaded constructor | overload (when variants differ by arg type) or named constructor (when they don't) | see [Constructors](#named-constructors-instead-of-overloading) |
| `Object` | `Literal` variant object | no universal value type in Nim — see [Object → Literal](#object--literal) |
| `null` | `nil` (only for `ref` types) | `object` value types have no `nil` — see [null → nil](#null--nil-only-for-ref-types) |
| `throw`/checked exceptions | `raise`/`object of CatchableError` | mostly direct; one notable divergence — see [Exceptions](#exceptions-error-returns-rather-than-throws) |
| `LoxCallable` interface | variant `ref object` (`LoxFunction` with `lfLox`/`lfNative`) | rare case where a variant beats `case`-on-`Literal` — see [Callables](#callables-loxcallable--variant-loxfunction) |
| `HashMap` | `Table` (value) / `TableRef` (reference) | Java's `Map` is always reference-typed; Nim splits it |
| generated `.java` files via `GenerateAst.java` | hand-written variant objects | short enough to write directly, no codegen needed |
| `Resolver implements Expr.Visitor, Stmt.Visitor` | `resolveExpr`/`resolveStmt` procs on a `Resolver` object | same visitor-avoidance as the interpreter — see [Resolver](#resolver-no-visitor-depth-stored-on-the-node) |

## Variant objects instead of inheritance + visitor

The book's `Expr`/`Stmt` are class hierarchies, and operations over them
(`AstPrinter`, `Interpreter`) use the visitor pattern — double dispatch via
`accept()`/`visitXyz()` — to work around Java's lack of sum types.

Nim has sum types natively: variant objects (`case` inside an `object`). See
`Expr`/`ExprKind` in `exprsn.nim` and `Stmt`/`StmtKind` in `stmt.nim`. Any
operation is one recursive proc with `case expr.kind` — no `accept`, no
visitor interface, no `GenerateAst.java` step.

A new `visitXyzExpr`/`visitXyzStmt` method in the book becomes a new `of
ekXyz:`/`of skXyz:` branch in the relevant `case`. Adding a variant makes
every existing `case` over that enum non-exhaustive, forcing a new branch
everywhere — a compiler-enforced checklist Java doesn't have.

**Tradeoff:** all `of` branches share one field namespace, so fields that
would be independently named in separate Java subclasses (`Unary.right` vs.
`Binary.right`) need distinct names — `unaryRight`/`right`,
`printExpr`/`expression`, etc.

Where the book splits `Logical` from `Binary` for its own visitor method, no
separate variant is needed — short-circuiting is just a check inside the
`ekBinary` branch of `evaluate` before evaluating both sides.

## Named constructors instead of overloading

`Literal`'s variants are distinguished by type (`bool`/`float`/`string`), so
one overloaded `initLiteral` works. `Expr`/`Stmt` variants often share
argument types (`skExpression` and `skPrint` both wrap an `Expr`), so
overloading would be ambiguous — these get named constructors instead
(`newBinary`, `newPrintStmt`, etc.).

## `Object` → `Literal`

Java uses `Object` (+ autoboxing) as the universal runtime value. Nim has no
universal value type, so `Literal`/`LiteralKind` (`types.nim`) is an explicit
variant object covering nil/bool/float/string, used for both token literals
and runtime values.

Things Java gets free via inheritance (`equals()`, `toString()`,
`instanceof`) are hand-written `case`-based procs (`isEqual`, `$`,
`isTruthy`) — more verbose, but exhaustiveness-checked.

## `null` → `nil`, only for `ref` types

Nim's `nil` is only valid for `ref` types, not `object` value types.

- `Literal` (`object`) — no `nil` Literal. Lox `nil` is `Literal(kind:
  lkNil)`, via `initLiteral()`.
- `Expr`/`Stmt` (`ref object`) — `nil` works like Java's `null`, e.g. an
  absent `var` initializer:

  ```nim
  var initializer: Expr = nil
  if p.match(tkEqual):
    initializer = p.expression()
  ```

## Exceptions: `error()` returns rather than throws

The book's `Parser.error()` returns a `ParseError` rather than throwing,
letting the caller decide whether to unwind:

```nim
raise p.parseError("Expect expression.")        # unwind
discard p.parseError("Some non-fatal issue.")   # report only, keep going
```

`ParseError`/`RuntimeError` are `object of CatchableError` in `error.nim`.
`RuntimeError` carries `token*: Token` (via `newRuntimeError`) for
line-number reporting.

A third variant — report without raising — shows up in `assignment()` for
the invalid-assignment-target case: `loxError(Token, string)` reports and
sets `hadError`, no exception involved.

## Callables: `LoxCallable` → variant `LoxFunction`

The book uses a `LoxCallable` interface implemented by native functions and
Lox-defined functions. Since both need to live under one `lkFunction`
variant on `Literal` but carry different state, this is one of the few spots
where a variant `ref object` is the better fit over `case`-on-`Literal`:

```nim
LoxFunction* = ref object
  arity*: int
  case kind*: LoxFunctionKind
  of lfLox: declaration*: Stmt; closure*: Environment
  of lfNative: nativeFn*: proc(args: seq[Literal]): Literal
```

New native functions are just another proc matching `nativeFn`'s signature.

## Resolver: no visitor, depth stored on the node

Chapter 11's `Resolver` is, again, a Java `Visitor` — same pattern as
`Interpreter`/`AstPrinter`, same fix: a `Resolver` object holding a scope
stack (`scopes*: seq[Table[string, bool]]`), and `resolveExpr`/`resolveStmt`
procs that `case` over `ExprKind`/`StmtKind` instead of implementing
`visitXyz` methods.

The bigger divergence is how resolved variable depth gets stored. The book
keys a `Map<Expr, Integer>` on the `Interpreter` by `Expr` object identity.
Nim's `Table` needs `==`/`hash` on the key type, and reference-identity
hashing isn't worth fighting for — so depth is stored directly as a field on
the relevant `Expr` variants instead:

```nim
of ekVar:
  name*: Token
  varDepth*: int = -1
of ekAssign:
  token*: Token
  assignExpr*: Expr
  assignDepth*: int = -1
```

`-1` is the sentinel for "not resolved locally" (a global). `resolveLocal`
walks the scope stack from innermost out and sets the field directly on the
`ref object` node — no side table needed. `evaluate` then branches on the
sentinel:

```nim
of ekVar:
  if ex.varDepth == -1: env.get(ex.name)
  else: env.getAt(ex.varDepth, ex.name)
```

`Environment` gains `getAt`/`assignAt`, which walk `enclosing` exactly
`depth` times rather than searching outward until found — the resolved depth
replaces the dynamic search entirely for locals.
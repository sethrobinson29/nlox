# nlox — Tree-Walk Interpreter

A Nim implementation of the Lox tree-walk interpreter from Part II of
[Crafting Interpreters](https://craftinginterpreters.com/) by Robert Nystrom.

## About

Rather than following the Java reference implementation directly, this port
translates the core ideas into Nim — replacing the visitor pattern with variant
objects and `case` dispatch, free procs instead of class methods, and Nim's
module system in place of Java's class hierarchy. The translation has tradeoffs;
it isn't a straightforward win in either direction. See
[translation-notes.md](translation-notes.md) for a detailed breakdown of the
decisions and where they diverged from the Java source.

## Usage

Build:

```bash
nim compile lox.nim
```

Run a script:

```bash
./lox script.lox
```

Run the REPL:

```bash
./lox
```

The REPL accepts both statements (terminated with `;`) and bare expressions.

## Extensions

A few features beyond the base book implementation:

- Multiline block comments (`/* ... */`)
- `break` statements in loops
- Anonymous functions / lambdas

## Experience

<!-- your section here -->
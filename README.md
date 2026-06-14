# nlox

Working through [Crafting Interpreters](https://craftinginterpreters.com/) by Robert Nystrom, implemented in Nim.

## About

Lox is a dynamically typed scripting language built across the book. This implementation covers both the tree-walk interpreter and bytecode virtual machine from the book, with idiomatic adjustments for Nim.

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

## REPL

The REPL accepts both statements (terminated with `;`) and bare expressions.
Entering an expression without a semicolon evaluates and prints the result
directly.

## Dependencies

Nim — developed on 2.2.x. Earlier versions may work but are untested.

## Translation Notes

Following along with the book in Java? See [JAVA_TO_NIM.md](JAVA_TO_NIM.md)
for a breakdown of where and why this implementation diverges from the Java
reference.

## Status

Work in progress, following the book chapter by chapter.
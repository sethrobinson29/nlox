# nlox

Working through [Crafting Interpreters](https://craftinginterpreters.com/) by Robert Nystrom, implemented in Nim.

## About

Lox is a dynamically typed scripting language built across the book. This repo contains both the tree-walk interpreter (Part II) and bytecode virtual machine (Part III), each in its own folder.

## Structure

- `v1/` — Tree-walk interpreter. See [v1/README.md](v1/README.md).
- `v2/` — Bytecode VM. Work in progress. (Paused as of 06/28/2026)

## Dependencies

Nim — developed on 2.2.x. Earlier versions may work but are untested.

## Status

(Update 06/28/2026)
After working with C-to-Nim for a few days, I feel like the translation is getting in the way of the interpreter. Writing Nim like it's C feels antithetical to the language and its ideas. Nim feels like something that's meant to flow and abstract away a lot of the low-level work that C requires of you. Due to this, I'm going to pump the breaks on v2, opting instead to implement the bytecode VM in C to further understand the design of the interpreter. After, I will refresh and build upon my understanding of Nim, and attempt to implement the bytecode VM in a more idiomatic Nim, as opposed to just writing it in C, which would result in an ugly usage of the language and implementation of the interpreter. Upon returning, I will more than likely remove all of the old code, but I'm committing and leaving it for history/tranparency.